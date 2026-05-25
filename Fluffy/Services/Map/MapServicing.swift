//
//  MapServicing.swift
//  Fluffy
//

protocol MapServicing {
    func fetchMarkers(in viewport: MapViewport, filters: Set<MapMarkerKind>) async throws -> [MapMarker]
}
