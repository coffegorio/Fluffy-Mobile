//
//  MockMapService.swift
//  Fluffy
//

import Foundation

struct MockMapService: MapServicing {
    func fetchMarkers(in viewport: MapViewport, filters: Set<MapMarkerKind>) async throws -> [MapMarker] {
        let activeFilters = filters.isEmpty ? Set(MapMarkerKind.allCases) : filters

        return MockMapData.markers.filter { marker in
            activeFilters.contains(marker.kind)
                && marker.latitude <= viewport.northEastLatitude
                && marker.latitude >= viewport.southWestLatitude
                && marker.longitude <= viewport.northEastLongitude
                && marker.longitude >= viewport.southWestLongitude
        }
    }
}

private enum MockMapData {
    static let markers: [MapMarker] = [
        MapMarker(
            id: "listing-1",
            kind: .rehome,
            title: "Бадди ищет дом",
            subtitle: "Липецк, Хамовники",
            latitude: 52.6031,
            longitude: 39.5708,
            imageURL: MockMarketplaceData.listings.first { $0.id == "1" }?.imageURL,
            isUrgent: true,
            target: .listing("1")
        ),
        MapMarker(
            id: "listing-8",
            kind: .lost,
            title: "Потерялась такса Бетти",
            subtitle: "Липецк, Сокольники",
            latitude: 52.6207,
            longitude: 39.5984,
            imageURL: MockMarketplaceData.listings.first { $0.id == "8" }?.imageURL,
            isUrgent: true,
            target: .listing("8")
        ),
        MapMarker(
            id: "listing-3",
            kind: .found,
            title: "Найден рыжий кот",
            subtitle: "Липецк, Марьино",
            latitude: 52.5822,
            longitude: 39.5188,
            imageURL: MockMarketplaceData.listings.first { $0.id == "3" }?.imageURL,
            isUrgent: false,
            target: .listing("3")
        ),
        MapMarker(
            id: "shelter-1",
            kind: .shelter,
            title: "Лучший друг",
            subtitle: "Приют, Липецк",
            latitude: 52.5618,
            longitude: 39.6324,
            imageURL: MockMarketplaceData.shelters.first?.imageURL,
            isUrgent: true,
            target: .shelters
        ),
        MapMarker(
            id: "petsitter-1",
            kind: .petSitter,
            title: "Елена Васильева",
            subtitle: "Pet-sitting, Липецк",
            latitude: 52.6446,
            longitude: 39.5369,
            imageURL: MockMarketplaceData.petSitters.first?.avatarURL,
            isUrgent: false,
            target: .petSitting
        )
    ]
}
