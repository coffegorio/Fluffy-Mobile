//
//  ExploreView.swift
//  Fluffy
//

import Observation
import SwiftUI

struct ExploreView: View {
    let viewModel: MainViewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("explore_title")
                            .font(.system(size: 24, weight: .heavy))

                        Spacer()

                        Button {
                            viewModel.showMap()
                        } label: {
                            Label("map_title", systemImage: "map.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppTheme.accent)
                                .padding(.horizontal, 12)
                                .frame(height: 36)
                                .background(AppTheme.surface.opacity(0.62), in: Capsule())
                                .overlay {
                                    Capsule()
                                        .stroke(.white.opacity(0.72), lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }

                    MarketplaceSearchBar(
                        text: $viewModel.searchText,
                        placeholder: "explore_search_placeholder"
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                CategoryPickerView(activeCategory: viewModel.selectedCategory) { category in
                    viewModel.selectedCategory = category
                }

                if let errorMessage = viewModel.errorMessage, viewModel.listings.isEmpty {
                    MarketplaceErrorStateView(message: errorMessage, retry: viewModel.refresh)
                } else if viewModel.isLoading && viewModel.listings.isEmpty {
                    LazyVStack(spacing: 12) {
                        ForEach(0..<5, id: \.self) { _ in
                            ListingRowCardSkeleton()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                } else if viewModel.filteredListings.isEmpty {
                    MarketplaceEmptyStateView(
                        title: "explore_empty_title",
                        subtitle: "explore_empty_subtitle"
                    )
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredListings) { listing in
                            ListingRowCard(
                                listing: listing,
                                isFavorite: viewModel.isFavorite(listing),
                                onFavorite: { viewModel.toggleFavorite(listing) },
                                onTap: { viewModel.showListing(listing) }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .scrollIndicators(.hidden)
        .refreshable {
            await viewModel.refresh()
        }
        .background(AppTheme.background)
    }
}
