//
//  APICityService.swift
//  Fluffy
//

import Foundation

struct APICityService: CityServicing {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchCities() async throws -> [City] {
        let response: CityListResponse = try await client.get("/api/v1/cities")
        return response.cities
    }
}

private struct CityListResponse: Decodable {
    let cities: [City]
}
