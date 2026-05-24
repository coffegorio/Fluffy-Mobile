//
//  FavoritesView.swift
//  Fluffy
//

import SwiftUI

struct FavoritesView: View {
    let viewModel: MainViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("favorites_title")
                        .font(.system(size: 24, weight: .heavy))

                    Text("\(viewModel.favoriteListings.count) \(String(localized: "favorites_count_suffix"))")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                if let errorMessage = viewModel.errorMessage, viewModel.listings.isEmpty {
                    MarketplaceErrorStateView(message: errorMessage, retry: viewModel.refresh)
                } else if viewModel.isLoading && viewModel.listings.isEmpty {
                    LazyVStack(spacing: 12) {
                        ForEach(0..<4, id: \.self) { _ in
                            ListingRowCardSkeleton()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                } else if viewModel.favoriteListings.isEmpty {
                    MarketplaceEmptyStateView(
                        title: "favorites_empty_title",
                        subtitle: "favorites_empty_subtitle"
                    )
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.favoriteListings) { listing in
                            ListingRowCard(
                                listing: listing,
                                isFavorite: true,
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
