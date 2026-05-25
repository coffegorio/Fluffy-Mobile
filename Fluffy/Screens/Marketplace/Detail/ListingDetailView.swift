//
//  ListingDetailView.swift
//  Fluffy
//

import SwiftUI

struct ListingDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let viewModel: MainViewModel
    let listing: Listing

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                content
            }
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.background)
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden()
    }

    private var hero: some View {
        ZStack(alignment: .top) {
            RemoteImageView(url: listing.imageURL)
                .frame(height: 330)
                .clipped()
                .overlay(alignment: .bottomLeading) {
                    if listing.isUrgent {
                        UrgentPillView()
                            .padding(16)
                    }
                }

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AppTheme.text)
                        .frame(width: 40, height: 40)
                        .background(.white, in: Circle())
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                }
                .accessibilityLabel(Text("common_back"))

                Spacer()

                FavoriteButton(
                    isFavorite: viewModel.isFavorite(listing),
                    action: { viewModel.toggleFavorite(listing) }
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 58)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(listing.title)
                        .font(.system(size: 25, weight: .heavy))
                        .lineLimit(3)

                    HStack {
                        ListingBadge(category: listing.category)

                        if let price = listing.pricePerDay {
                            Text("\(price) ₽ \(String(localized: "common_per_day"))")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                }

                Spacer()

                Image(systemName: listing.animalType.systemImage)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
                    .accessibilityHidden(true)
            }

            infoGrid
            tags
            description
            location
            author
            messageButton
        }
        .padding(16)
        .padding(.top, 4)
        .background(AppTheme.background)
    }

    private var infoGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            DetailInfoTile(title: "detail_breed", value: listing.breed)
            DetailInfoTile(title: "detail_age", value: listing.age)
            DetailInfoTile(title: "detail_sex", value: String(localized: listing.sex == .male ? "pet_sex_male" : "pet_sex_female"))
            DetailInfoTile(title: "detail_area", value: listing.city)
        }
    }

    private var tags: some View {
        FlowLayout(spacing: 8) {
            ForEach(listing.tags, id: \.self) { tag in
                Text(tag)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(AppTheme.accentSoft, in: Capsule())
            }
        }
    }

    private var description: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("detail_description")
                .font(.system(size: 17, weight: .heavy))

            Text(listing.description)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.secondaryText)
                .lineSpacing(4)
        }
    }

    private var location: some View {
        Label(listing.location, systemImage: "mappin.and.ellipse")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(AppTheme.text)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.muted, in: RoundedRectangle(cornerRadius: AppTheme.compactRadius))
    }

    private var author: some View {
        HStack(spacing: 12) {
            RemoteImageView(url: listing.authorAvatarURL)
                .frame(width: 48, height: 48)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(listing.authorName)
                    .font(.system(size: 15, weight: .bold))
                Text(listing.date)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(AppTheme.accent)
        }
        .padding(12)
        .background(AppTheme.surface.opacity(0.70), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.12))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    private var messageButton: some View {
        Button {
            viewModel.startChat(for: listing)
        } label: {
            Label("detail_write", systemImage: "message.fill")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        }
        .buttonStyle(.plain)
    }
}

private struct DetailInfoTile: View {
    let title: LocalizedStringKey
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.secondaryText)

            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.text)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppTheme.muted, in: RoundedRectangle(cornerRadius: AppTheme.compactRadius))
    }
}
