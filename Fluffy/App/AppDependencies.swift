//
//  AppDependencies.swift
//  Fluffy
//
//  Created by Egor Matveev on 25.04.2026.
//

import Foundation

struct AppDependencies {
    let authService: AuthServicing
    let authSessionStore: AuthSessionStoring
    let marketplaceService: MarketplaceServicing
    let mapService: MapServicing

    static var live: AppDependencies {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-UseMockAuth")
            || ProcessInfo.processInfo.arguments.contains("-UITestAuthEmail") {
            return AppDependencies(
                authService: MockAuthService(),
                authSessionStore: KeychainAuthSessionStore(),
                marketplaceService: MockMarketplaceService(),
                mapService: MockMapService()
            )
        }
        #endif

        return AppDependencies(
            authService: APIAuthService(),
            authSessionStore: KeychainAuthSessionStore(),
            marketplaceService: MockMarketplaceService(),
            mapService: MockMapService()
        )
    }
}
