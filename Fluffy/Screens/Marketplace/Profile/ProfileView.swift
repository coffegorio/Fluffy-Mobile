//
//  ProfileView.swift
//  Fluffy
//

import SwiftUI

struct ProfileView: View {
    let viewModel: MainViewModel

    private let menuItems: [(LocalizedStringKey, String, ProfileMenuAction)] = [
        ("profile_menu_listings", "list.bullet.rectangle", .listings),
        ("profile_menu_notifications", "bell", .notifications),
        ("profile_menu_security", "lock.shield", .security),
        ("profile_menu_help", "bubble.left.and.bubble.right", .help),
        ("profile_menu_about", "info.circle", .about)
    ]

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("tab_profile")
                        .font(.system(size: 24, weight: .heavy))

                    if let errorMessage = viewModel.errorMessage, viewModel.profile == nil {
                        MarketplaceErrorStateView(message: errorMessage, retry: viewModel.refresh)
                    } else if let profile = viewModel.profile {
                        profileHeader(profile)
                        if viewModel.isVerificationRequired {
                            verificationNotice
                        }
                        stats(profile)
                        myListings
                        menu
                        signOutButton
                    } else if viewModel.isLoading {
                        ProfileSkeletonView()
                    } else {
                        MarketplaceErrorStateView(message: String(localized: "marketplace_load_error"), retry: viewModel.refresh)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 22)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scrollIndicators(.hidden)
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    private func profileHeader(_ profile: UserProfile) -> some View {
        HStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                RemoteImageView(url: profile.avatarURL)
                    .frame(width: 82, height: 82)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.accent, lineWidth: 2))

                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 23, height: 23)
                    .background(AppTheme.accent, in: Circle())
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(profile.name)
                    .font(.system(size: 20, weight: .heavy))
                Text("\(profile.handle) · \(profile.city)")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.secondaryText)
                HStack(spacing: 8) {
                    RatingView(rating: profile.rating)
                    Text("\(profile.reviews) \(String(localized: "profile_reviews"))")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            Spacer()
        }
    }

    private var verificationNotice: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 38, height: 38)
                .background(AppTheme.accentSoft, in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text("profile_verification_title")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(AppTheme.text)

                Text("profile_verification_message")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(AppTheme.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.12))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    private func stats(_ profile: UserProfile) -> some View {
        HStack(spacing: 8) {
            ProfileStat(value: "\(profile.listingsCount)", title: "profile_stat_listings")
            ProfileStat(value: "\(profile.dealsCount)", title: "profile_stat_deals")
            ProfileStat(value: "\(profile.daysOnPlatform)", title: "profile_stat_days")
        }
    }

    private var myListings: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("profile_my_listings")
                .font(.system(size: 17, weight: .heavy))

            ForEach(viewModel.myListings) { listing in
                Button {
                    viewModel.showListing(listing)
                } label: {
                    HStack(spacing: 12) {
                        RemoteImageView(url: listing.imageURL)
                            .frame(width: 54, height: 54)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 5) {
                            Text(listing.title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(AppTheme.text)
                                .lineLimit(1)
                            ListingBadge(category: listing.category)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(12)
                    .background(AppTheme.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                    .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.12), isInteractive: true)
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var menu: some View {
        VStack(spacing: 0) {
            ForEach(Array(menuItems.enumerated()), id: \.offset) { index, item in
                Button {
                    viewModel.showProfileAction(item.2)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: item.1)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 24)

                        Text(item.0)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.text)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 15)
                }
                .buttonStyle(.plain)

                if index < menuItems.count - 1 {
                    Divider()
                        .padding(.leading, 50)
                }
            }
        }
        .background(AppTheme.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.12))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    private var signOutButton: some View {
        Button(role: .destructive) {
            viewModel.signOut()
        } label: {
            Label("profile_sign_out", systemImage: "rectangle.portrait.and.arrow.right")
                .font(.system(size: 15, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
        }
        .buttonStyle(.bordered)
    }
}

private struct ProfileStat: View {
    let value: String
    let title: LocalizedStringKey

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 20, weight: .heavy))
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppTheme.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.12))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
}
