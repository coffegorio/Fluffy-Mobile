//
//  AppDependencies.swift
//  Fluffy
//
//  Created by Egor Matveev on 25.04.2026.
//

struct AppDependencies {
    let authService: AuthServicing
    let authSessionStore: AuthSessionStoring
    let marketplaceService: MarketplaceServicing
    let mapService: MapServicing

    static let live = AppDependencies(
        authService: MockAuthService(),
        authSessionStore: KeychainAuthSessionStore(),
        marketplaceService: MockMarketplaceService(),
        mapService: MockMapService()
    )
}
