//
//  FavoriteButton.swift
//  Fluffy
//

import SwiftUI

struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(isFavorite ? AppTheme.danger : Color.gray)
                .frame(width: 34, height: 34)
                .background(.white.opacity(0.92), in: Circle())
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(isFavorite ? "favorite_remove" : "favorite_add"))
    }
}
