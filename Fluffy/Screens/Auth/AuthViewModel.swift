//
//  AuthViewModel.swift
//  Fluffy
//
//  Created by Egor Matveev on 25.04.2026.
//

import Foundation
import Observation
import SwiftUI

protocol AuthCoordinating: AnyObject {
    func showWelcome()
    func showHome(session: AuthSession)
}

enum AuthStep {
    case email
    case code
}

@Observable
final class AuthViewModel {
    var email = ""
    var code = ""
    var step: AuthStep = .email
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

        #if DEBUG
        if let email = ProcessInfo.processInfo.value(after: "-UITestAuthEmail")
            ?? ProcessInfo.processInfo.value(after: "-PrefillAuthEmail") {
            self.email = email
        }
        #endif
    }

    func backTapped() {
        if step == .code {
            step = .email
            code = ""
            errorMessage = nil
        } else {
            coordinator?.showWelcome()
        }
    }

    var primaryButtonTitle: LocalizedStringKey {
        switch step {
        case .email: "auth_send_code_button"
        case .code: "auth_verify_code_button"
        }
    }

    var isPrimaryActionEnabled: Bool {
        switch step {
        case .email:
            email.trimmingCharacters(in: .whitespacesAndNewlines).contains("@")
        case .code:
            !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    func primaryActionTapped() {
        guard !isLoading else { return }

        Task {
            switch step {
            case .email:
                await requestCode()
            case .code:
                await verifyCode()
            }
        }
    }
}

private extension AuthViewModel {
    func requestCode() async {
        await runAuthAction {
            try await authService.requestSignInCode(email: normalizedEmail)
            #if DEBUG
            code = ProcessInfo.processInfo.value(after: "-UITestAuthCode") ?? ""
            #else
            code = ""
            #endif
            step = .code
        }
    }

    func verifyCode() async {
        await runAuthAction {
            let session = try await authService.verifySignInCode(email: normalizedEmail, code: code)
            coordinator?.showHome(session: session)
        }
    }

    var normalizedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func runAuthAction(_ action: () async throws -> Void) async {
        isLoading = true
        errorMessage = nil

        do {
            try await action()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = String(localized: "auth_generic_error")
        }
    }
}

#if DEBUG
private extension ProcessInfo {
    func value(after key: String) -> String? {
        guard let index = arguments.firstIndex(of: key),
              arguments.indices.contains(index + 1)
        else {
            return nil
        }

        return arguments[index + 1]
    }
}
#endif
