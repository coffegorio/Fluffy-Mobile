//
//  APIMapService.swift
//  Fluffy
//

import Foundation

struct APIMapService: MapServicing {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchMarkers(in viewport: MapViewport, filters: Set<MapMarkerKind>) async throws -> [MapMarker] {
        let activeFilters = filters.isEmpty ? Set(MapMarkerKind.allCases) : filters
        let categories = activeFilters.flatMap(\.backendCategories).joined(separator: ",")
        let response: MapMarkersResponse = try await client.get(
            "/api/v1/map/markers",
            queryItems: [
                URLQueryItem(name: "north", value: "\(viewport.northEastLatitude)"),
                URLQueryItem(name: "south", value: "\(viewport.southWestLatitude)"),
                URLQueryItem(name: "east", value: "\(viewport.northEastLongitude)"),
                URLQueryItem(name: "west", value: "\(viewport.southWestLongitude)"),
                URLQueryItem(name: "categories", value: categories),
                URLQueryItem(name: "limit", value: "200")
            ]
        )
        return response.markers.map(\.marker)
    }
}

private struct MapMarkersResponse: Decodable {
    let markers: [BackendMapMarkerResponse]
}

private struct BackendMapMarkerResponse: Decodable {
    let id: String
    let targetType: String
    let targetId: String
    let category: String
    let title: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
    let isUrgent: Bool
    let previewImageUrl: String?

    var marker: MapMarker {
        let kind = MapMarkerKind(backendCategory: category)
        return MapMarker(
            id: id,
            kind: kind,
            title: title,
            subtitle: subtitle,
            latitude: latitude,
            longitude: longitude,
            imageURL: URL(string: previewImageUrl ?? ""),
            isUrgent: isUrgent,
            target: targetType == "listing" ? .listing(targetId) : kind.defaultTarget
        )
    }
}

private extension MapMarkerKind {
    var backendCategories: [String] {
        switch self {
        case .lost:
            ["lost", "lostPet"]
        case .found:
            ["found", "foundPet"]
        case .rehome:
            ["rehome", "adoption"]
        case .shelter:
            ["shelters"]
        case .petSitter:
            ["petsitting", "petSitting"]
        }
    }

    init(backendCategory: String) {
        switch backendCategory {
        case "lost", "lostPet":
            self = .lost
        case "found", "foundPet":
            self = .found
        case "shelters":
            self = .shelter
        case "petsitting", "petSitting":
            self = .petSitter
        default:
            self = .rehome
        }
    }

    var defaultTarget: MapMarkerTarget {
        switch self {
        case .shelter:
            .shelters
        case .petSitter:
            .petSitting
        case .lost, .found, .rehome:
            .listing("")
        }
    }
}
