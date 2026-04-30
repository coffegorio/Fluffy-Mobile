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
    var path = NavigationPath()

    private let dependencies: AppDependencies

    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
    }

    @ViewBuilder
    func rootView() -> some View {
        switch root {
        case .welcome:
            WelcomeView(viewModel: makeWelcomeViewModel())
        case .auth:
            AuthView(viewModel: makeAuthViewModel())
        case .home:
            HomeView()
        }
    }

    @ViewBuilder
    func destination(for route: AppRoute) -> some View {
        switch route {
        case .signUp:
            PlaceholderRouteView(title: "Sign Up")
        case .forgotPassword:
            PlaceholderRouteView(title: "Forgot Password")
        }
    }
}

extension AppCoordinator: WelcomeCoordinating {
    func showAuth() {
        root = .auth
        path = NavigationPath()
    }
}

extension AppCoordinator: AuthCoordinating {
    func showWelcome() {
        root = .welcome
        path = NavigationPath()
    }

    func showSignUp() {
        path.append(AppRoute.signUp)
    }

    func showForgotPassword() {
        path.append(AppRoute.forgotPassword)
    }

    func showHome() {
        root = .home
        path = NavigationPath()
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
}
