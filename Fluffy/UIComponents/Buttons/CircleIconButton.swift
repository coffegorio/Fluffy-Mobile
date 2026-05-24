//
//  CircleIconButton.swift
//  Fluffy
//
//  Created by Egor Matveev on 24.04.2026.
//

import SwiftUI

struct CircleIconButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    let action: () -> Void

    @ScaledMetric private var iconSize = CircleIconButtonLayout.iconSize

    var body: some View {
        HStack {
            Button(title, systemImage: systemImage, action: action)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(.primary)
                .labelStyle(.iconOnly)
                .frame(width: CircleIconButtonLayout.size, height: CircleIconButtonLayout.size)
                .background(.white.opacity(0.55))
                .fluffyGlass(cornerRadius: CircleIconButtonLayout.size / 2, tint: .white.opacity(0.18), isInteractive: true)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.12), radius: 10, y: 4)

            Spacer()
        }
    }
}

private enum CircleIconButtonLayout {
    static let size: CGFloat = 40
    static let iconSize: CGFloat = 16
}
