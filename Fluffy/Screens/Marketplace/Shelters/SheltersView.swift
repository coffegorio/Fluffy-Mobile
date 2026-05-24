//
//  SheltersView.swift
//  Fluffy
//

import SwiftUI

struct SheltersView: View {
    let viewModel: MainViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                BackHeaderView(title: "shelters_title")
                    .padding(.horizontal, -16)

                Text("shelters_subtitle")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.secondaryText)

                if let errorMessage = viewModel.errorMessage, viewModel.shelters.isEmpty {
                    MarketplaceErrorStateView(message: errorMessage, retry: viewModel.refresh)
                } else if viewModel.isLoading && viewModel.shelters.isEmpty {
                    LazyVStack(spacing: 14) {
                        ForEach(0..<3, id: \.self) { _ in
                            ShelterCardSkeleton()
                        }
                    }
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(viewModel.shelters) { shelter in
                            ShelterCard(
                                shelter: shelter,
                                onHelp: { viewModel.requestHelp(for: shelter) }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .refreshable {
            await viewModel.refresh()
        }
        .background(AppTheme.background)
        .navigationBarBackButtonHidden()
    }
}

private struct ShelterCard: View {
    let shelter: Shelter
    let onHelp: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                RemoteImageView(url: shelter.imageURL)
                    .frame(height: 150)
                    .overlay(.black.opacity(0.28))

                VStack(alignment: .leading, spacing: 4) {
                    Text(shelter.name)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(.white)
                    Label(shelter.city, systemImage: "mappin.and.ellipse")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.84))
                }
                .padding(14)

                if shelter.urgentCount > 0 {
                    VStack {
                        HStack {
                            Spacer()
                            Text("\(String(localized: "shelter_urgent")): \(shelter.urgentCount)")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppTheme.danger, in: Capsule())
                        }
                        Spacer()
                    }
                    .padding(12)
                }
            }

            VStack(alignment: .leading, spacing: 13) {
                Text(shelter.description)
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineSpacing(3)

                HStack {
                    Label("\(shelter.animals) \(String(localized: "shelter_animals"))", systemImage: "pawprint.fill")
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                    Text("shelter_looking_home")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                HStack(spacing: 10) {
                    Button(action: onHelp) {
                        Label("shelter_help", systemImage: "heart.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ShelterButtonStyle(isPrimary: true))

                    if let phoneURL = shelter.phoneURL {
                        Link(destination: phoneURL) {
                            Label("common_call", systemImage: "phone.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(ShelterButtonStyle(isPrimary: false))
                    }
                }
                .font(.system(size: 14, weight: .bold))
            }
            .padding(14)
        }
        .background(AppTheme.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
}

private extension Shelter {
    var phoneURL: URL? {
        let digits = phone.filter(\.isNumber)
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel://\(digits)")
    }
}

private struct ShelterButtonStyle: ButtonStyle {
    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isPrimary ? .white : AppTheme.text)
            .padding(.vertical, 12)
            .background(isPrimary ? AppTheme.accent : AppTheme.muted, in: RoundedRectangle(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
