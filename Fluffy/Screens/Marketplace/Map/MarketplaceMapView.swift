//
//  MarketplaceMapView.swift
//  Fluffy
//

import MapKit
import SwiftUI

struct MarketplaceMapView: View {
    let viewModel: MainViewModel

    @State private var position: MapCameraPosition

    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
        _position = State(initialValue: .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: viewModel.selectedCity.latitude, longitude: viewModel.selectedCity.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.22, longitudeDelta: 0.36)
            )
        ))
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $position) {
                ForEach(viewModel.mapMarkers) { marker in
                    Annotation(marker.title, coordinate: marker.coordinate) {
                        Button {
                            viewModel.showMapMarker(marker)
                        } label: {
                            MapMarkerBubble(marker: marker)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .mapControls {
                MapCompass()
            }
            .ignoresSafeArea()

            VStack(spacing: 12) {
                BackHeaderView(title: "map_title")

                mapFilters
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            if !viewModel.isLoading && viewModel.mapMarkers.isEmpty {
                VStack {
                    Spacer()
                    MarketplaceEmptyStateView(
                        title: "map_empty_title",
                        subtitle: LocalizedStringKey(String(format: String(localized: "map_empty_subtitle"), viewModel.selectedCity.name))
                    )
                    .background(AppTheme.surface.opacity(0.74), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 92)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .task {
            await viewModel.loadMapMarkers()
        }
    }

    private var mapFilters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(MapMarkerKind.allCases) { filter in
                    Button {
                        viewModel.toggleMapFilter(filter)
                    } label: {
                        Label(filter.titleKey, systemImage: filter.systemImage)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(viewModel.selectedMapFilters.contains(filter) ? .white : AppTheme.text)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.selectedMapFilters.contains(filter)
                                    ? filter.tint
                                    : AppTheme.surface.opacity(0.74),
                                in: Capsule()
                            )
                            .overlay {
                                Capsule()
                                    .stroke(.white.opacity(0.62), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
    }
}

private struct MapMarkerBubble: View {
    let marker: MapMarker

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: marker.kind.systemImage)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(marker.kind.tint, in: Circle())
                    .shadow(color: .black.opacity(0.18), radius: 8, y: 4)

                if marker.isUrgent {
                    Circle()
                        .fill(AppTheme.danger)
                        .frame(width: 11, height: 11)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }
            }

            Text(marker.title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(AppTheme.surface.opacity(0.86), in: Capsule())
                .shadow(color: .black.opacity(0.08), radius: 5, y: 2)
                .frame(maxWidth: 118)
        }
    }
}
