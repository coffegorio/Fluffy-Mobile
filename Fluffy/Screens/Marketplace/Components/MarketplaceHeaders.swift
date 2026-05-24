//
//  MarketplaceHeaders.swift
//  Fluffy
//

import SwiftUI

struct SectionHeaderView: View {
    let title: LocalizedStringKey
    var actionTitle: LocalizedStringKey?
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(AppTheme.text)

            Spacer()

            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: 3) {
                        Text(actionTitle)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct BackHeaderView: View {
    @Environment(\.dismiss) private var dismiss

    let title: LocalizedStringKey
    var trailing: AnyView?

    var body: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppTheme.text)
                    .frame(width: 38, height: 38)
                    .background(AppTheme.surface, in: Circle())
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
            }
            .accessibilityLabel(Text("common_back"))

            Text(title)
                .font(.system(size: 18, weight: .heavy))
                .lineLimit(1)

            Spacer()

            trailing
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 6)
        .background(AppTheme.surface.opacity(0.36), in: RoundedRectangle(cornerRadius: 26))
        .fluffyGlass(cornerRadius: 26, tint: .white.opacity(0.12))
    }
}

struct MarketplaceEmptyStateView: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(AppTheme.accent)
                .accessibilityHidden(true)

            Text(title)
                .font(.system(size: 17, weight: .bold))

            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
    }
}

struct MarketplaceErrorStateView: View {
    let message: String
    let retry: () async -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(AppTheme.danger)
                .accessibilityHidden(true)

            Text("marketplace_error_title")
                .font(.system(size: 17, weight: .heavy))

            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await retry()
                }
            } label: {
                Label("common_retry", systemImage: "arrow.clockwise")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)
                    .background(AppTheme.accent, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}
