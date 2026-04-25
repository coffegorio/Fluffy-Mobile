//
//  AuthBackButton.swift
//  Fluffy
//
//  Created by Egor Matveev on 24.04.2026.
//

import SwiftUI

struct AuthBackButton: View {
    let action: () -> Void

    @ScaledMetric private var iconSize = AuthLayout.backButtonIconSize

    var body: some View {
        HStack {
            Button("auth_back_button", systemImage: "chevron.left", action: action)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(.primary)
                .labelStyle(.iconOnly)
                .frame(width: AuthLayout.backButtonSize, height: AuthLayout.backButtonSize)
                .background(.white.opacity(0.92))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.12), radius: 10, y: 4)

            Spacer()
        }
    }
}
