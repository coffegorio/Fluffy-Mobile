//
//  AuthPanel.swift
//  Fluffy
//
//  Created by Egor Matveev on 24.04.2026.
//

import SwiftUI

struct AuthPanel: View {
    @Binding var email: String
    @Binding var code: String

    let step: AuthStep
    let isLoading: Bool
    let isPrimaryActionEnabled: Bool
    let primaryButtonTitle: LocalizedStringKey
    let errorMessage: String?
    let onPrimaryAction: () -> Void

    var body: some View {
        ZStack {
            AuthWaveShape()
                .fill(Color.white)
                .ignoresSafeArea(.container, edges: .bottom)

            VStack(alignment: .leading, spacing: 0) {
                AuthHeader()

                AuthForm(
                    email: $email,
                    code: $code,
                    step: step
                )

                AuthActions(
                    title: primaryButtonTitle,
                    isLoading: isLoading,
                    isEnabled: isPrimaryActionEnabled,
                    action: onPrimaryAction
                )
                .padding(.top, AuthLayout.actionsTopPadding)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.danger)
                        .padding(.top, 12)
                }
            }
            .padding(.horizontal, AuthLayout.horizontalPadding)
            .padding(.top, AuthLayout.contentTopPadding)
            .padding(.bottom, AuthLayout.bottomPadding)
        }
        .frame(height: AuthLayout.panelHeight)
    }
}
