//
//  AuthenticatedAPIClient.swift
//  Fluffy
//

import Foundation

struct AuthenticatedAPIClient {
    let client: APIClient
    let sessionStore: AuthSessionStoring
    let authService: AuthServicing

    func accessToken() async throws -> String {
        guard let session = sessionStore.loadSession() else {
            throw APIClientError.api(code: "unauthenticated", message: "Authentication is required.")
        }

        guard session.expiresAt <= Date().addingTimeInterval(60) else {
            return session.accessToken
        }

        let refreshed = try await authService.refreshSession(session)
        sessionStore.saveSession(refreshed)
        return refreshed.accessToken
    }
}
