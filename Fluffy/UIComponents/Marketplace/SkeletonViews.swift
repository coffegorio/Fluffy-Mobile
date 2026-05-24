//
//  SkeletonViews.swift
//  Fluffy
//

import SwiftUI

struct SkeletonBlock: View {
    var cornerRadius: CGFloat = 10
    var tint: Color = AppTheme.surface.opacity(0.78)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(tint)
            .overlay {
                if !reduceMotion {
                    GeometryReader { proxy in
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.52),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: proxy.size.width * 0.72)
                        .offset(x: isAnimating ? proxy.size.width * 1.35 : -proxy.size.width)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                }
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.18).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
            .accessibilityHidden(true)
    }
}

struct SkeletonLine: View {
    var width: CGFloat?
    var height: CGFloat = 12
    var cornerRadius: CGFloat = 6

    var body: some View {
        SkeletonBlock(cornerRadius: cornerRadius)
            .frame(width: width, height: height)
    }
}

struct MarketplaceHomeSkeletonView: View {
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                skeletonSectionHeader

                HStack(spacing: 12) {
                    ListingGridCardSkeleton()
                    ListingGridCardSkeleton()
                }
            }

            SkeletonBlock(cornerRadius: AppTheme.cardRadius)
                .frame(height: 104)

            SkeletonBlock(cornerRadius: AppTheme.cardRadius)
                .frame(height: 104)

            VStack(spacing: 12) {
                skeletonSectionHeader

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(0..<4, id: \.self) { _ in
                        ListingGridCardSkeleton()
                    }
                }
            }
        }
    }

    private var skeletonSectionHeader: some View {
        HStack {
            SkeletonLine(width: 180, height: 22, cornerRadius: 8)
            Spacer()
            SkeletonLine(width: 42, height: 14, cornerRadius: 7)
        }
    }
}

struct ListingGridCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SkeletonBlock(cornerRadius: 0)
                .frame(height: 142)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        SkeletonLine(width: 92, height: 14)
                        SkeletonLine(width: 72, height: 14)
                    }

                    Spacer()

                    SkeletonBlock(cornerRadius: 8)
                        .frame(width: 18, height: 18)
                }

                SkeletonLine(height: 11)
                SkeletonLine(width: 88, height: 18, cornerRadius: 9)
                SkeletonLine(width: 116, height: 10)
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 292, alignment: .top)
        .background(AppTheme.surface.opacity(0.70))
        .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .shadow(color: .black.opacity(0.035), radius: 8, y: 4)
    }
}

struct ListingRowCardSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonBlock(cornerRadius: 12)
                .frame(width: 78, height: 78)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    SkeletonLine(width: 150, height: 15)
                    Spacer()
                    SkeletonBlock(cornerRadius: 16)
                        .frame(width: 32, height: 32)
                }

                SkeletonLine(width: 128, height: 12)
                SkeletonLine(width: 176, height: 11)

                HStack {
                    SkeletonLine(width: 86, height: 18, cornerRadius: 9)
                    Spacer()
                    SkeletonLine(width: 54, height: 10)
                }
            }
        }
        .padding(12)
        .background(AppTheme.surface.opacity(0.70), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.10))
        .shadow(color: .black.opacity(0.035), radius: 8, y: 4)
    }
}

struct ConversationRowSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonBlock(cornerRadius: 26)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    SkeletonLine(width: 128, height: 14)
                    Spacer()
                    SkeletonLine(width: 42, height: 10)
                }

                SkeletonLine(width: 156, height: 10)
                SkeletonLine(height: 12)
            }
        }
        .padding(12)
        .background(AppTheme.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .shadow(color: .black.opacity(0.035), radius: 8, y: 4)
    }
}

struct ProfileSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
                SkeletonBlock(cornerRadius: 41)
                    .frame(width: 82, height: 82)

                VStack(alignment: .leading, spacing: 8) {
                    SkeletonLine(width: 150, height: 20)
                    SkeletonLine(width: 118, height: 13)
                    SkeletonLine(width: 96, height: 12)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonBlock(cornerRadius: AppTheme.cardRadius)
                        .frame(height: 68)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                SkeletonLine(width: 132, height: 18)
                ForEach(0..<2, id: \.self) { _ in
                    ListingRowCardSkeleton()
                }
            }

            VStack(spacing: 0) {
                ForEach(0..<5, id: \.self) { index in
                    HStack(spacing: 12) {
                        SkeletonBlock(cornerRadius: 8)
                            .frame(width: 24, height: 24)
                        SkeletonLine(width: 146, height: 14)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 15)

                    if index < 4 {
                        Divider()
                            .padding(.leading, 50)
                    }
                }
            }
            .background(AppTheme.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
            .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.10))
            .shadow(color: .black.opacity(0.035), radius: 8, y: 4)
        }
    }
}

struct ShelterCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SkeletonBlock(cornerRadius: 0)
                .frame(height: 150)

            VStack(alignment: .leading, spacing: 13) {
                SkeletonLine(height: 13)
                SkeletonLine(width: 220, height: 13)
                SkeletonLine(width: 152, height: 14)

                HStack(spacing: 10) {
                    SkeletonBlock(cornerRadius: 12)
                        .frame(height: 44)
                    SkeletonBlock(cornerRadius: 12)
                        .frame(height: 44)
                }
            }
            .padding(14)
        }
        .background(AppTheme.surface.opacity(0.70), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .shadow(color: .black.opacity(0.035), radius: 8, y: 4)
    }
}

struct PetSitterCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                SkeletonBlock(cornerRadius: 16)
                    .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        SkeletonLine(width: 140, height: 15)
                        Spacer()
                        SkeletonLine(width: 58, height: 15)
                    }
                    SkeletonLine(width: 116, height: 11)
                    SkeletonLine(width: 178, height: 11)
                }
            }

            SkeletonLine(height: 12)
            SkeletonLine(width: 236, height: 12)

            HStack(spacing: 7) {
                SkeletonLine(width: 72, height: 24, cornerRadius: 12)
                SkeletonLine(width: 86, height: 24, cornerRadius: 12)
                SkeletonLine(width: 64, height: 24, cornerRadius: 12)
            }

            HStack {
                SkeletonLine(width: 70, height: 18)
                Spacer()
                SkeletonBlock(cornerRadius: 12)
                    .frame(width: 96, height: 38)
            }
        }
        .padding(14)
        .background(AppTheme.surface.opacity(0.70), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.10))
        .shadow(color: .black.opacity(0.035), radius: 8, y: 4)
    }
}
