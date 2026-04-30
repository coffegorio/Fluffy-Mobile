//
//  AuthViewModel.swift
//  Fluffy
//
//  Created by Egor Matveev on 25.04.2026.
//

import Foundation
import Observation

protocol AuthCoordinating: AnyObject {
    func showWelcome()
    func showSignUp()
    func showForgotPassword()
    func showHome()
}

@Observable
final class AuthViewModel {
    var email = ""
    var password = ""
    var isLoading = false
    var errorMessage: String?

    private weak var coordinator: AuthCoordinating?
    private let authService: AuthServicing

    init(
        coordinator: AuthCoordinating?,
        authService: AuthServicing
    ) {
        self.coordinator = coordinator
        self.authService = authService
    }

    func backTapped() {
        coordinator?.showWelcome()
    }

    func signInTapped() {
        guard !isLoading else { return }

        Task {
            await signIn()
        }
    }

    func forgotPasswordTapped() {
        coordinator?.showForgotPassword()
    }

    func signUpTapped() {
        coordinator?.showSignUp()
    }

    func googleSignInTapped() {
        guard !isLoading else { return }

        Task {
            await signInWithGoogle()
        }
    }

    func facebookSignInTapped() {
        guard !isLoading else { return }

        Task {
            await signInWithFacebook()
        }
    }
}

private extension AuthViewModel {
    func signIn() async {
        await runAuthAction {
            try await authService.signIn(email: email, password: password)
        }
    }

    func signInWithGoogle() async {
        await runAuthAction {
            try await authService.signInWithGoogle()
        }
    }

    func signInWithFacebook() async {
        await runAuthAction {
            try await authService.signInWithFacebook()
        }
    }

    func runAuthAction(_ action: () async throws -> Void) async {
        isLoading = true
        errorMessage = nil

        do {
            try await action()
            isLoading = false
            coordinator?.showHome()
        } catch {
            isLoading = false
            errorMessage = String(localized: "auth_generic_error")
        }
    }
}
