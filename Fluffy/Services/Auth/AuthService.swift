//
//  AuthService.swift
//  Fluffy
//
//  Created by Egor Matveev on 25.04.2026.
//

import Foundation

struct AuthUser: Codable, Hashable {
    let id: String
    let email: String
}

struct AuthSession: Codable, Hashable {
    let accessToken: String
    let user: AuthUser
    var requiresProfileCompletion: Bool
}

protocol AuthServicing {
    func requestSignInCode(email: String) async throws
    func verifySignInCode(email: String, code: String) async throws -> AuthSession
}

struct MockAuthService: AuthServicing {
    func requestSignInCode(email: String) async throws {}

    func verifySignInCode(email: String, code: String) async throws -> AuthSession {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return AuthSession(
            accessToken: "mock-token-\(UUID().uuidString)",
            user: AuthUser(id: normalizedEmail, email: normalizedEmail),
            requiresProfileCompletion: normalizedEmail != "tester@example.com"
        )
    }
}
