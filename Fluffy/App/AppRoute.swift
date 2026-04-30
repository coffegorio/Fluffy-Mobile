//
//  AppRoute.swift
//  Fluffy
//
//  Created by Egor Matveev on 25.04.2026.
//

enum AppRoot {
    case welcome
    case auth
    case home
}

enum AppRoute: Hashable {
    case signUp
    case forgotPassword
}
