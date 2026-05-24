//
//  PetSittingView.swift
//  Fluffy
//

import SwiftUI

struct PetSittingView: View {
    let viewModel: MainViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                BackHeaderView(title: "petsitting_title")

                VStack(alignment: .leading, spacing: 5) {
                    Text("petsitting_banner_title")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                    Text("petsitting_banner_subtitle")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(AppTheme.accentSoft.opacity(0.72), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: AppTheme.accent.opacity(0.10))
                .padding(.horizontal, 16)

                if let errorMessage = viewModel.errorMessage, viewModel.petSitters.isEmpty {
                    MarketplaceErrorStateView(message: errorMessage, retry: viewModel.refresh)
                        .padding(.horizontal, 16)
                } else if viewModel.isLoading && viewModel.petSitters.isEmpty {
                    LazyVStack(spacing: 12) {
                        ForEach(0..<4, id: \.self) { _ in
                            PetSitterCardSkeleton()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.petSitters) { sitter in
                            PetSitterCard(
                                sitter: sitter,
                                onContact: { viewModel.contactPetSitter(sitter) }
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
        .navigationBarBackButtonHidden()
    }
}

private struct PetSitterCard: View {
    let sitter: PetSitter
    let onContact: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                RemoteImageView(url: sitter.avatarURL)
                    .frame(width: 58, height: 58)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .top) {
                        Text(sitter.name)
                            .font(.system(size: 15, weight: .heavy))
                            .lineLimit(2)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 0) {
                            Text("\(sitter.pricePerDay) ₽")
                                .font(.system(size: 15, weight: .heavy))
                                .foregroundStyle(AppTheme.accent)
                            Text("common_per_day")
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }

                    HStack(spacing: 8) {
                        RatingView(rating: sitter.rating)
                        Text("\(sitter.reviews) \(String(localized: "profile_reviews"))")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Label(sitter.location, systemImage: "mappin.and.ellipse")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            Text(sitter.bio)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.secondaryText)
                .lineSpacing(3)

            FlowLayout(spacing: 7) {
                ForEach(sitter.services, id: \.self) { service in
                    Text(service)
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(AppTheme.muted, in: Capsule())
                }
            }

            HStack {
                HStack(spacing: 4) {
                    ForEach(sitter.animalTypes) { animal in
                        Image(systemName: animal.systemImage)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                            .accessibilityHidden(true)
                    }
                }

                Spacer()

                Button(action: onContact) {
                    Text("detail_write")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                        .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(AppTheme.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.12))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
}
