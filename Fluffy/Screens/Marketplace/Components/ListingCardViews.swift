//
//  ListingCardViews.swift
//  Fluffy
//

import SwiftUI

struct ListingGridCard: View {
    let listing: Listing
    let isFavorite: Bool
    let onFavorite: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    RemoteImageView(url: listing.imageURL)
                        .frame(height: 142)
                        .clipShape(Rectangle())

                    FavoriteButton(isFavorite: isFavorite, action: onFavorite)
                        .padding(8)

                    if listing.isUrgent {
                        VStack {
                            HStack {
                                UrgentPillView()
                                Spacer()
                            }
                            Spacer()
                        }
                        .padding(8)
                    }
                }

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .top, spacing: 4) {
                        Text(listing.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppTheme.text)
                            .lineLimit(2)

                        Spacer(minLength: 2)

                        Image(systemName: listing.animalType.systemImage)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                            .accessibilityHidden(true)
                    }

                    Text("\(listing.breed) · \(listing.age)")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)

                    HStack {
                        listingMeta
                    }

                    Label(listing.location, systemImage: "mappin.and.ellipse")
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                }
                .padding(12)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 292, alignment: .top)
            .fixedSize(horizontal: false, vertical: true)
            .background(AppTheme.surface.opacity(0.72))
            .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.12), isInteractive: true)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var listingMeta: some View {
        if let price = listing.pricePerDay {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) {
                    ListingBadge(category: listing.category)
                        .layoutPriority(1)

                    Spacer(minLength: 4)

                    priceText(price)
                }

                VStack(alignment: .leading, spacing: 6) {
                    ListingBadge(category: listing.category)
                    priceText(price)
                }
            }
        } else {
            ListingBadge(category: listing.category)
        }
    }

    private func priceText(_ price: Int) -> some View {
        Text("\(price) ₽\(String(localized: "common_per_day_short"))")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(AppTheme.accent)
            .lineLimit(1)
            .minimumScaleFactor(0.74)
    }
}

struct ListingRowCard: View {
    let listing: Listing
    let isFavorite: Bool
    let onFavorite: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack(alignment: .topLeading) {
                    RemoteImageView(url: listing.imageURL)
                        .frame(width: 78, height: 78)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    if listing.isUrgent {
                        Text("!")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 18, height: 18)
                            .background(AppTheme.danger, in: Circle())
                            .offset(x: -4, y: -4)
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(listing.title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(AppTheme.text)
                            .lineLimit(2)

                        Spacer(minLength: 4)

                        FavoriteButton(isFavorite: isFavorite, action: onFavorite)
                    }

                    Text("\(listing.breed) · \(listing.age)")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.secondaryText)

                    Label(listing.location, systemImage: "mappin.and.ellipse")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)

                    HStack {
                        ListingBadge(category: listing.category)
                        Spacer()
                        Text(listing.date)
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
            .padding(12)
            .background(AppTheme.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
            .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.12), isInteractive: true)
            .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}
