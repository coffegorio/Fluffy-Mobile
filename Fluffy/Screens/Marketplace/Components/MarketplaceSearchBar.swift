//
//  MarketplaceSearchBar.swift
//  Fluffy
//

import SwiftUI

struct MarketplaceSearchBar: View {
    @Binding var text: String
    var placeholder: LocalizedStringKey

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.secondaryText)

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.secondaryText.opacity(0.7))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("common_clear"))
            }
        }
        .font(.system(size: 15))
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(AppTheme.surface.opacity(0.52), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .fluffyGlass(cornerRadius: AppTheme.cardRadius, tint: .white.opacity(0.12), isInteractive: true)
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
    }
}
