//
//  AppCoordinator.swift
//  Fluffy
//
//  Created by Egor Matveev on 25.04.2026.
//

import Observation
import SwiftUI

@Observable
final class AppCoordinator {
    var root: AppRoot = .welcome
    var path: [AppRoute] = []

    private let dependencies: AppDependencies
    private var currentSession: AuthSession?

    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies

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

        if let session = dependencies.authSessionStore.loadSession() {
            currentSession = session
            root = session.requiresProfileCompletion ? .profileCompletion : .home
        }
    }

    @ViewBuilder
    func rootView() -> some View {
        switch root {
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
    }
}

extension AppCoordinator: ProfileCompletionCoordinating {
    func profileCompletionDidFinish(session: AuthSession) {
        currentSession = session
        dependencies.authSessionStore.saveSession(session)
        path = []
        root = .home
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
        let session = currentSession
        dependencies.authSessionStore.clearSession()
        currentSession = nil
        path = []
        root = .welcome

        if let session {
            Task {
                try? await dependencies.authService.logout(session: session, allDevices: false)
            }
        }
    }
}

private extension AppCoordinator {
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
            mediaService: dependencies.mediaService
        )
    }

    func makeProfileCompletionViewModel(session: AuthSession) -> ProfileCompletionViewModel {
        ProfileCompletionViewModel(
            session: session,
            coordinator: self,
            marketplaceService: dependencies.marketplaceService,
            mediaService: dependencies.mediaService
        )
    }
}
