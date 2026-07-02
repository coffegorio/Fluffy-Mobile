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
    let mediaService: MediaServicing
    let cityService: CityServicing
    let citySelectionStore: CitySelectionStoring
    let accessTokenProvider: AccessTokenProviding

    static var live: AppDependencies {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-UseMockAuth")
            || ProcessInfo.processInfo.arguments.contains("-UITestAuthEmail") {
            return AppDependencies(
                authService: MockAuthService(),
                authSessionStore: KeychainAuthSessionStore(),
                marketplaceService: MockMarketplaceService(),
                mapService: MockMapService(),
                mediaService: MockMediaService(),
                cityService: MockCityService(),
                citySelectionStore: UserDefaultsCitySelectionStore(),
                accessTokenProvider: AuthenticatedAPIClient(
                    client: APIClient(configuration: .live),
                    sessionStore: KeychainAuthSessionStore(),
                    authService: MockAuthService()
                )
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
            mapService: APIMapService(client: apiClient),
            mediaService: APIMediaService(client: apiClient, authenticatedClient: authenticatedClient),
            cityService: APICityService(client: apiClient),
            citySelectionStore: UserDefaultsCitySelectionStore(),
            accessTokenProvider: authenticatedClient
        )
    }
}
