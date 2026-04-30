//
//  AppDependencies.swift
//  Fluffy
//
//  Created by Egor Matveev on 25.04.2026.
//

struct AppDependencies {
    let authService: AuthServicing

    static let live = AppDependencies(
        authService: MockAuthService()
    )
}
