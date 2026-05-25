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
            subtitle: "Москва, Хамовники",
            latitude: 55.7358,
            longitude: 37.5930,
            imageURL: MockMarketplaceData.listings.first { $0.id == "1" }?.imageURL,
            isUrgent: true,
            target: .listing("1")
        ),
        MapMarker(
            id: "listing-8",
            kind: .lost,
            title: "Потерялась такса Бетти",
            subtitle: "Москва, Сокольники",
            latitude: 55.7565,
            longitude: 37.6248,
            imageURL: MockMarketplaceData.listings.first { $0.id == "8" }?.imageURL,
            isUrgent: true,
            target: .listing("8")
        ),
        MapMarker(
            id: "listing-3",
            kind: .found,
            title: "Найден рыжий кот",
            subtitle: "Москва, Марьино",
            latitude: 55.6508,
            longitude: 37.7437,
            imageURL: MockMarketplaceData.listings.first { $0.id == "3" }?.imageURL,
            isUrgent: false,
            target: .listing("3")
        ),
        MapMarker(
            id: "shelter-1",
            kind: .shelter,
            title: "Лучший друг",
            subtitle: "Приют, Москва",
            latitude: 55.6641,
            longitude: 37.5182,
            imageURL: MockMarketplaceData.shelters.first?.imageURL,
            isUrgent: true,
            target: .shelters
        ),
        MapMarker(
            id: "petsitter-1",
            kind: .petSitter,
            title: "Елена Васильева",
            subtitle: "Pet-sitting, Москва",
            latitude: 55.8005,
            longitude: 37.5301,
            imageURL: MockMarketplaceData.petSitters.first?.avatarURL,
            isUrgent: false,
            target: .petSitting
        )
    ]
}
