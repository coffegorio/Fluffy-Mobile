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

        let apiClient = APIClient(configuration: .live)
        let authService = APIAuthService(client: apiClient)
        let sessionStore = KeychainAuthSessionStore()
        let authenticatedClient = AuthenticatedAPIClient(
            client: apiClient,
            sessionStore: sessionStore,
            authService: authService
        )

        return AppDependencies(
            authService: authService,
            authSessionStore: sessionStore,
            marketplaceService: APIMarketplaceService(
                client: apiClient,
                authenticatedClient: authenticatedClient,
                sessionStore: sessionStore
            ),
            mapService: APIMapService(client: apiClient)
        )
    }
}
