//
//  AuthActions.swift
//  Fluffy
//
//  Created by Egor Matveev on 24.04.2026.
//

import SwiftUI

struct AuthActions: View {
    let title: LocalizedStringKey
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }

                Text(title)
                    .font(.system(size: AuthLayout.primaryButtonFontSize, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: AuthLayout.primaryButtonHeight)
            .background(AppTheme.accent.opacity(isEnabled ? 0.92 : 0.45), in: Capsule())
            .fluffyProminentGlass(cornerRadius: AuthLayout.primaryButtonHeight / 2, tint: AppTheme.accent.opacity(0.34))
        }
        .disabled(!isEnabled || isLoading)
    }
}
