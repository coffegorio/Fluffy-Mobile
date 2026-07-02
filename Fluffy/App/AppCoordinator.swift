//
//  AppCoordinator.swift
//  Fluffy
//
//  Created by Egor Matveev on 25.04.2026.
//

import Observation
import SwiftUI
import UIKit
import UserNotifications

@Observable
final class AppCoordinator {
    var root: AppRoot = .launching
    var path: [AppRoute] = []

    private let dependencies: AppDependencies
    @ObservationIgnored private let deviceIDProvider: DeviceIDProviding
    @ObservationIgnored private var pushTokenObserver: NSObjectProtocol?
    @ObservationIgnored private var pushRegistrationFailureObserver: NSObjectProtocol?
    @ObservationIgnored private var pushRegistrationTask: Task<Void, Never>?
    private var currentSession: AuthSession?
    private var pendingPushToken: String?
    private var registeredPushToken: String?

    init(
        dependencies: AppDependencies = .live,
        deviceIDProvider: DeviceIDProviding = UserDefaultsDeviceIDProvider()
    ) {
        self.dependencies = dependencies
        self.deviceIDProvider = deviceIDProvider
        observePushRegistrationEvents()

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ResetAuthSession") {
            dependencies.authSessionStore.clearSession()
        }

        if ProcessInfo.processInfo.arguments.contains("-UITestAuthenticated") {
            currentSession = AuthSession(
                accessToken: "ui-test-token",
                refreshToken: "ui-test-refresh-token",
                expiresAt: Date().addingTimeInterval(15 * 60),
                user: AuthUser(id: "tester@example.com", email: "tester@example.com"),
                role: .verifiedUser,
                verificationStatus: .approved,
                requiresProfileCompletion: false
            )
            root = .home
            return
        }
        #endif

        guard let session = dependencies.authSessionStore.loadSession() else {
            root = .welcome
            return
        }

        currentSession = session
        Task { @MainActor in
            await restoreStoredSession(session)
        }
    }

    deinit {
        if let pushTokenObserver {
            NotificationCenter.default.removeObserver(pushTokenObserver)
        }
        if let pushRegistrationFailureObserver {
            NotificationCenter.default.removeObserver(pushRegistrationFailureObserver)
        }
        pushRegistrationTask?.cancel()
    }

    @ViewBuilder
    func rootView() -> some View {
        switch root {
        case .launching:
            ProgressView()
                .tint(AppTheme.accent)
        case .welcome:
            WelcomeView(viewModel: makeWelcomeViewModel())
        case .auth:
            AuthView(viewModel: makeAuthViewModel())
        case .profileCompletion:
            if let currentSession {
                ProfileCompletionView(viewModel: makeProfileCompletionViewModel(session: currentSession))
            } else {
                WelcomeView(viewModel: makeWelcomeViewModel())
            }
        case .home:
            MainView(viewModel: makeMainViewModel())
        }
    }

    @ViewBuilder
    func destination(for route: AppRoute) -> some View {
        switch route {
        case .auth:
            AuthView(viewModel: makeAuthViewModel())
        }
    }
}

extension AppCoordinator: WelcomeCoordinating {
    func showAuth() {
        path.append(AppRoute.auth)
    }
}

extension AppCoordinator: AuthCoordinating {
    func showWelcome() {
        path = []
        root = .welcome
    }

    func showHome(session: AuthSession) {
        dependencies.authSessionStore.saveSession(session)
        currentSession = session
        path = []
        root = session.requiresProfileCompletion ? .profileCompletion : .home
        activatePushRegistrationIfNeeded()
    }
}

extension AppCoordinator: ProfileCompletionCoordinating {
    func profileCompletionDidFinish(session: AuthSession) {
        currentSession = session
        dependencies.authSessionStore.saveSession(session)
        path = []
        root = .home
        activatePushRegistrationIfNeeded()
    }

    func cancelProfileCompletion() {
        signOut()
    }
}

extension AppCoordinator: MainCoordinating {
    func updateSession(_ session: AuthSession) {
        currentSession = session
        dependencies.authSessionStore.saveSession(session)
    }

    func signOut() {
        signOut(allDevices: false)
    }

    func signOut(allDevices: Bool) {
        let session = currentSession
        let deviceID = deviceIDProvider.deviceID
        pushRegistrationTask?.cancel()
        pendingPushToken = nil
        registeredPushToken = nil
        currentSession = nil
        path = []
        root = .welcome

        if let session {
            Task { @MainActor in
                if dependencies.authSessionStore.loadSession()?.refreshToken == session.refreshToken {
                    _ = try? await dependencies.marketplaceService.unregisterPushDevice(deviceID: deviceID)
                }
                _ = try? await dependencies.authService.logout(session: session, allDevices: allDevices)
                if dependencies.authSessionStore.loadSession()?.refreshToken == session.refreshToken {
                    dependencies.authSessionStore.clearSession()
                }
            }
        } else {
            dependencies.authSessionStore.clearSession()
        }
    }
}

private extension AppCoordinator {
    func observePushRegistrationEvents() {
        pushTokenObserver = NotificationCenter.default.addObserver(
            forName: .fluffyAPNsDeviceTokenDidUpdate,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let token = notification.userInfo?["token"] as? String else { return }
            self?.handlePushToken(token)
        }

        pushRegistrationFailureObserver = NotificationCenter.default.addObserver(
            forName: .fluffyAPNsDeviceTokenRegistrationDidFail,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pushRegistrationTask?.cancel()
            self?.pushRegistrationTask = nil
        }
    }

    func restoreStoredSession(_ session: AuthSession) async {
        guard session.expiresAt <= Date().addingTimeInterval(60) else {
            currentSession = session
            root = session.requiresProfileCompletion ? .profileCompletion : .home
            activatePushRegistrationIfNeeded()
            return
        }

        do {
            let refreshed = try await dependencies.authService.refreshSession(session)
            dependencies.authSessionStore.saveSession(refreshed)
            currentSession = refreshed
            root = refreshed.requiresProfileCompletion ? .profileCompletion : .home
            activatePushRegistrationIfNeeded()
        } catch {
            dependencies.authSessionStore.clearSession()
            currentSession = nil
            path = []
            root = .welcome
        }
    }

    func activatePushRegistrationIfNeeded() {
        guard canRegisterPushNotifications else { return }

        pushRegistrationTask?.cancel()
        pushRegistrationTask = Task { @MainActor [weak self] in
            await self?.requestPushAuthorizationAndRegister()
        }
    }

    func handlePushToken(_ token: String) {
        pendingPushToken = token
        Task { @MainActor [weak self] in
            await self?.sendPushTokenIfPossible()
        }
    }

    func requestPushAuthorizationAndRegister() async {
        guard canRegisterPushNotifications else { return }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let isAllowed: Bool

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            isAllowed = true
        case .notDetermined:
            isAllowed = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        case .denied:
            isAllowed = false
        @unknown default:
            isAllowed = false
        }

        guard isAllowed else { return }
        UIApplication.shared.registerForRemoteNotifications()
        await sendPushTokenIfPossible()
    }

    func sendPushTokenIfPossible() async {
        guard canRegisterPushNotifications,
              let token = pendingPushToken,
              token != registeredPushToken
        else {
            return
        }

        do {
            let device = try await dependencies.marketplaceService.registerPushDevice(
                token: token,
                deviceID: deviceIDProvider.deviceID,
                environment: pushEnvironment
            )
            if device.enabled {
                registeredPushToken = token
            }
        } catch {
            registeredPushToken = nil
        }
    }

    var canRegisterPushNotifications: Bool {
        currentSession != nil && root == .home && isRunningUITests == false
    }

    var pushEnvironment: PushEnvironment {
        #if DEBUG
        .sandbox
        #else
        .production
        #endif
    }

    var isRunningUITests: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains { $0.hasPrefix("-UITest") }
        #else
        false
        #endif
    }

    func makeWelcomeViewModel() -> WelcomeViewModel {
        WelcomeViewModel(coordinator: self)
    }

    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(
            coordinator: self,
            authService: dependencies.authService
        )
    }

    func makeMainViewModel() -> MainViewModel {
        MainViewModel(
            session: currentSession,
            coordinator: self,
            marketplaceService: dependencies.marketplaceService,
            mapService: dependencies.mapService,
            mediaService: dependencies.mediaService,
            cityService: dependencies.cityService,
            citySelectionStore: dependencies.citySelectionStore,
            accessTokenProvider: dependencies.accessTokenProvider
        )
    }

    func makeProfileCompletionViewModel(session: AuthSession) -> ProfileCompletionViewModel {
        ProfileCompletionViewModel(
            session: session,
            coordinator: self,
            marketplaceService: dependencies.marketplaceService,
            mediaService: dependencies.mediaService,
            cityService: dependencies.cityService
        )
    }
}
