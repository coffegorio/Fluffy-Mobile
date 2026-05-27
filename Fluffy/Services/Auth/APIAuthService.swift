//
//  APIAuthService.swift
//  Fluffy
//

import Foundation

struct APIAuthService: AuthServicing {
    private let client: APIClient
    private let deviceIDProvider: DeviceIDProviding

    init(
        client: APIClient = APIClient(configuration: .live),
        deviceIDProvider: DeviceIDProviding = UserDefaultsDeviceIDProvider()
    ) {
        self.client = client
        self.deviceIDProvider = deviceIDProvider
    }

    func requestSignInCode(email: String) async throws {
        let request = EmailStartRequest(email: normalizedEmail(email))
        try await client.post("/api/v1/auth/email/start", body: request)
    }

    func verifySignInCode(email: String, code: String) async throws -> AuthSession {
        let request = EmailVerifyRequest(
            email: normalizedEmail(email),
            code: code.trimmingCharacters(in: .whitespacesAndNewlines),
            deviceId: deviceIDProvider.deviceID
        )
        return try await client.post("/api/v1/auth/email/verify", body: request)
    }

    func refreshSession(_ session: AuthSession) async throws -> AuthSession {
        let request = RefreshRequest(refreshToken: session.refreshToken, deviceId: deviceIDProvider.deviceID)
        return try await client.post("/api/v1/auth/refresh", body: request)
    }

    func logout(session: AuthSession, allDevices: Bool) async throws {
        let request = LogoutRequest(refreshToken: session.refreshToken, allDevices: allDevices)
        try await client.post("/api/v1/auth/logout", body: request, accessToken: session.accessToken)
    }

    private func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

private struct EmailStartRequest: Encodable {
    let email: String
}

private struct EmailVerifyRequest: Encodable {
    let email: String
    let code: String
    let deviceId: String
}

private struct RefreshRequest: Encodable {
    let refreshToken: String
    let deviceId: String
}

private struct LogoutRequest: Encodable {
    let refreshToken: String
    let allDevices: Bool
}
