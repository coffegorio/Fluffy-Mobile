//
//  AuthService.swift
//  Fluffy
//
//  Created by Egor Matveev on 25.04.2026.
//

protocol AuthServicing {
    func signIn(email: String, password: String) async throws
    func signInWithGoogle() async throws
    func signInWithFacebook() async throws
}

struct MockAuthService: AuthServicing {
    func signIn(email: String, password: String) async throws {}
    func signInWithGoogle() async throws {}
    func signInWithFacebook() async throws {}
}
