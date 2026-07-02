//
//  CityModels.swift
//  Fluffy
//

import Foundation

struct City: Identifiable, Hashable, Decodable {
    let slug: String
    let name: String
    let latitude: Double
    let longitude: Double
    let northEastLatitude: Double
    let northEastLongitude: Double
    let southWestLatitude: Double
    let southWestLongitude: Double

    var id: String { slug }

    var viewport: MapViewport {
        MapViewport(
            northEastLatitude: northEastLatitude,
            northEastLongitude: northEastLongitude,
            southWestLatitude: southWestLatitude,
            southWestLongitude: southWestLongitude,
            zoom: 11
        )
    }
}

enum CityCatalog {
    // Mirrors backend Sources/App/Domain/City.swift. Used as an offline fallback
    // when /api/v1/cities hasn't been fetched yet (cold start, no connectivity).
    static let fallback: [City] = [
        City(
            slug: "lipetsk",
            name: "Липецк",
            latitude: 52.6031,
            longitude: 39.5708,
            northEastLatitude: 52.72,
            northEastLongitude: 39.78,
            southWestLatitude: 52.48,
            southWestLongitude: 39.36
        ),
        City(
            slug: "voronezh",
            name: "Воронеж",
            latitude: 51.6720,
            longitude: 39.1843,
            northEastLatitude: 51.76,
            northEastLongitude: 39.35,
            southWestLatitude: 51.58,
            southWestLongitude: 39.05
        ),
        City(
            slug: "moscow",
            name: "Москва",
            latitude: 55.7558,
            longitude: 37.6173,
            northEastLatitude: 55.95,
            northEastLongitude: 37.95,
            southWestLatitude: 55.55,
            southWestLongitude: 37.25
        ),
        City(
            slug: "spb",
            name: "Санкт-Петербург",
            latitude: 59.9311,
            longitude: 30.3609,
            northEastLatitude: 60.08,
            northEastLongitude: 30.65,
            southWestLatitude: 59.75,
            southWestLongitude: 30.05
        )
    ]

    static var defaultCity: City { fallback[0] }
}
