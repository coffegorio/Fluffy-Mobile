//
//  AuthenticatedAPIClient.swift
//  Fluffy
//

import Foundation

protocol AccessTokenProviding {
    func accessToken() async throws -> String
}

struct AuthenticatedAPIClient: AccessTokenProviding {
    let client: APIClient
    let sessionStore: AuthSessionStoring
    let authService: AuthServicing

    func accessToken() async throws -> String {
        guard let session = sessionStore.loadSession() else {
            throw APIClientError.api(code: "unauthenticated", message: "Authentication is required.", requestID: nil)
        }

        guard session.expiresAt <= Date().addingTimeInterval(60) else {
            return session.accessToken
        }

        do {
            let refreshed = try await authService.refreshSession(session)
            sessionStore.saveSession(refreshed)
            return refreshed.accessToken
        } catch {
            if error.isUnauthorizedAPIError {
                sessionStore.clearSession()
            }
            throw error
        }
    }
}

private extension Error {
    var isUnauthorizedAPIError: Bool {
        guard let error = self as? APIClientError else { return false }
        switch error {
        case .httpStatus(401, _):
            return true
        case let .api(code, _, _):
            return code == "unauthorized"
        default:
            return false
        }
    }
}
