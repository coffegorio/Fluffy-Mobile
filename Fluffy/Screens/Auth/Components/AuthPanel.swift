//
//  AuthPanel.swift
//  Fluffy
//
//  Created by Egor Matveev on 24.04.2026.
//

import SwiftUI

struct AuthPanel: View {
    @Binding var email: String
    @Binding var password: String

    let onSignIn: () -> Void
    let onForgotPassword: () -> Void
    let onSignUp: () -> Void
    let onGoogleSignIn: () -> Void
    let onFacebookSignIn: () -> Void

    var body: some View {
        ZStack {
            AuthWaveShape()
                .fill(Color.white)
                .ignoresSafeArea(edges: .bottom)

            VStack(alignment: .leading, spacing: 0) {
                AuthHeader()

                AuthForm(
                    email: $email,
                    password: $password,
                    onForgotPassword: onForgotPassword
                )

                AuthActions(
                    onSignIn: onSignIn,
                    onSignUp: onSignUp,
                    onGoogleSignIn: onGoogleSignIn,
                    onFacebookSignIn: onFacebookSignIn
                )
                .padding(.top, AuthLayout.actionsTopPadding)
            }
            .padding(.horizontal, AuthLayout.horizontalPadding)
            .padding(.top, AuthLayout.contentTopPadding)
            .padding(.bottom, AuthLayout.bottomPadding)
        }
        .frame(height: AuthLayout.panelHeight)
    }
}
