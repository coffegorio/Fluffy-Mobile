//
//  MapModels.swift
//  Fluffy
//

import CoreLocation
import Foundation
import SwiftUI

struct MapViewport: Hashable {
    let northEastLatitude: Double
    let northEastLongitude: Double
    let southWestLatitude: Double
    let southWestLongitude: Double
    let zoom: Double

    static let lipetsk = MapViewport(
        northEastLatitude: 52.72,
        northEastLongitude: 39.78,
        southWestLatitude: 52.48,
        southWestLongitude: 39.36,
        zoom: 11
    )
}

struct MapMarker: Identifiable, Hashable {
    let id: String
    let kind: MapMarkerKind
    let title: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
    let imageURL: URL?
    let isUrgent: Bool
    let target: MapMarkerTarget

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum MapMarkerKind: String, CaseIterable, Identifiable, Hashable {
    case lost
    case found
    case rehome
    case shelter
    case petSitter

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .lost: "map_marker_lost"
        case .found: "map_marker_found"
        case .rehome: "map_marker_rehome"
        case .shelter: "map_marker_shelter"
        case .petSitter: "map_marker_pet_sitter"
        }
    }

    var systemImage: String {
        switch self {
        case .lost: "magnifyingglass"
        case .found: "checkmark.circle.fill"
        case .rehome: "house.fill"
        case .shelter: "heart.text.square.fill"
        case .petSitter: "figure.walk"
        }
    }

    var tint: Color {
        switch self {
        case .lost: AppTheme.danger
        case .found: AppTheme.success
        case .rehome, .shelter: AppTheme.accent
        case .petSitter: AppTheme.purple
        }
    }
}

enum MapMarkerTarget: Hashable {
    case listing(String)
    case shelters
    case petSitting
}
