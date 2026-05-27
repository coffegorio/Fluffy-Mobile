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

enum AuthRole: String, Codable, Hashable {
    case user
    case verifiedUser
    case moderator
    case admin
}

enum VerificationStatus: String, Codable, Hashable {
    case notStarted
    case pending
    case approved
    case rejected
}

struct AuthSession: Codable, Hashable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let user: AuthUser
    let role: AuthRole
    let verificationStatus: VerificationStatus
    var requiresProfileCompletion: Bool
}

protocol AuthServicing {
    func requestSignInCode(email: String) async throws
    func verifySignInCode(email: String, code: String) async throws -> AuthSession
    func refreshSession(_ session: AuthSession) async throws -> AuthSession
    func logout(session: AuthSession, allDevices: Bool) async throws
}

struct MockAuthService: AuthServicing {
    func requestSignInCode(email: String) async throws {}

    func verifySignInCode(email: String, code: String) async throws -> AuthSession {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return AuthSession(
            accessToken: "mock-token-\(UUID().uuidString)",
            refreshToken: "mock-refresh-token-\(UUID().uuidString)",
            expiresAt: Date().addingTimeInterval(15 * 60),
            user: AuthUser(id: normalizedEmail, email: normalizedEmail),
            role: normalizedEmail == "tester@example.com" ? .verifiedUser : .user,
            verificationStatus: normalizedEmail == "tester@example.com" ? .approved : .notStarted,
            requiresProfileCompletion: normalizedEmail != "tester@example.com"
        )
    }

    func refreshSession(_ session: AuthSession) async throws -> AuthSession {
        AuthSession(
            accessToken: "mock-token-\(UUID().uuidString)",
            refreshToken: "mock-refresh-token-\(UUID().uuidString)",
            expiresAt: Date().addingTimeInterval(15 * 60),
            user: session.user,
            role: session.role,
            verificationStatus: session.verificationStatus,
            requiresProfileCompletion: session.requiresProfileCompletion
        )
    }

    func logout(session: AuthSession, allDevices: Bool) async throws {}
}
