//
//  MarketplaceHomeView.swift
//  Fluffy
//

import SwiftUI

struct MarketplaceHomeView: View {
    let viewModel: MainViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                searchButton
                CategoryPickerView(activeCategory: .all) { _ in
                    viewModel.showExplore()
                }
                .padding(.horizontal, -16)

                if let errorMessage = viewModel.errorMessage, viewModel.listings.isEmpty {
                    MarketplaceErrorStateView(message: errorMessage, retry: viewModel.refresh)
                } else if viewModel.isLoading && viewModel.listings.isEmpty {
                    MarketplaceHomeSkeletonView()
                } else {
                    if viewModel.listings.isEmpty {
                        MarketplaceEmptyStateView(
                            title: "home_empty_title",
                            subtitle: "home_empty_subtitle"
                        )
                    } else {
                        if !viewModel.urgentListings.isEmpty {
                            urgentSection
                        }

                        HomePromoBanner(
                            eyebrow: "home_shelters_eyebrow",
                            title: "home_shelters_title",
                            subtitle: "home_shelters_subtitle",
                            systemImage: "heart.text.square.fill",
                            tint: .black.opacity(0.68),
                            imageURL: viewModel.shelters.first?.imageURL,
                            accessibilityIdentifier: "home_shelters_banner",
                            action: viewModel.showShelters
                        )

                        HomePromoBanner(
                            eyebrow: "home_petsitting_eyebrow",
                            title: "home_petsitting_title",
                            subtitle: "home_petsitting_subtitle",
                            systemImage: "figure.walk.motion",
                            tint: AppTheme.accent.opacity(0.85),
                            imageURL: viewModel.petSitters.first?.avatarURL,
                            accessibilityIdentifier: "home_petsitting_banner",
                            action: viewModel.showPetSitting
                        )

                        if !viewModel.recentListings.isEmpty {
                            recentSection
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .refreshable {
            await viewModel.refresh()
        }
        .background(AppTheme.background)
    }

    private var header: some View {
        HStack {
            Label("Липецк", systemImage: "mappin.and.ellipse")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(AppTheme.text)

            Spacer()

            Button {
                viewModel.showProfileAction(.notifications)
            } label: {
                Image(systemName: "bell")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.text)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.surface, in: Circle())
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            }
            .accessibilityLabel(Text("notifications"))
        }
    }

    private var searchButton: some View {
        Button {
            viewModel.showExplore()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppTheme.secondaryText)

                Text("home_search_placeholder")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.secondaryText)

                Spacer()
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(AppTheme.surface.opacity(0.52), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
            .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.12), isInteractive: true)
            .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var urgentSection: some View {
        VStack(spacing: 12) {
            SectionHeaderView(
                title: "home_urgent_title",
                actionTitle: "common_all",
                action: viewModel.showExplore
            )

            GeometryReader { proxy in
                let cardWidth = (proxy.size.width - 12) / 2

                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.urgentListings) { listing in
                            UrgentListingCard(
                                listing: listing,
                                width: cardWidth,
                                isFavorite: viewModel.isFavorite(listing),
                                onFavorite: { viewModel.toggleFavorite(listing) },
                                onTap: { viewModel.showListing(listing) }
                            )
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            .frame(height: 224)
        }
    }

    private var recentSection: some View {
        VStack(spacing: 12) {
            SectionHeaderView(
                title: "home_recent_title",
                actionTitle: "common_all",
                action: viewModel.showExplore
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.recentListings) { listing in
                    ListingGridCard(
                        listing: listing,
                        isFavorite: viewModel.isFavorite(listing),
                        onFavorite: { viewModel.toggleFavorite(listing) },
                        onTap: { viewModel.showListing(listing) }
                    )
                }
            }
        }
    }
}

private struct UrgentListingCard: View {
    let listing: Listing
    let width: CGFloat
    let isFavorite: Bool
    let onFavorite: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    RemoteImageView(url: listing.imageURL)
                        .frame(width: width, height: 128)

                    FavoriteButton(isFavorite: isFavorite, action: onFavorite)
                        .padding(8)

                    VStack {
                        HStack {
                            UrgentPillView()
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.title)
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(2)

                    Text(listing.breed)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)

                    Label(listing.city, systemImage: "mappin.and.ellipse")
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                }
                .padding(10)
            }
            .frame(width: width)
            .background(AppTheme.surface.opacity(0.72))
            .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.12), isInteractive: true)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

private struct HomePromoBanner: View {
    let eyebrow: LocalizedStringKey
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let systemImage: String
    let tint: Color
    let imageURL: URL?
    let accessibilityIdentifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .leading) {
                RemoteImageView(url: imageURL)
                    .frame(height: 114)
                    .overlay(tint)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(eyebrow)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.82))

                        Text(title)
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(.white)

                        Text(subtitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.82))
                    }

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.20), in: Circle())
                }
                .padding(.horizontal, 18)
            }
            .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.10), isInteractive: true)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}
