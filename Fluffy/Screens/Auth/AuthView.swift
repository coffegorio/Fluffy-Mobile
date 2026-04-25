//
//  AuthView.swift
//  Fluffy
//
//  Created by Egor Matveev on 24.04.2026.
//

import SwiftUI

struct AuthView: View {
    var onBack: () -> Void = {}
    var onSignIn: () -> Void = {}
    var onForgotPassword: () -> Void = {}
    var onSignUp: () -> Void = {}
    var onGoogleSignIn: () -> Void = {}
    var onFacebookSignIn: () -> Void = {}

    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        ZStack {
            WelcomeBackgroundView()

            VStack {
                Spacer()

                AuthPanel(
                    email: $email,
                    password: $password,
                    onSignIn: onSignIn,
                    onForgotPassword: onForgotPassword,
                    onSignUp: onSignUp,
                    onGoogleSignIn: onGoogleSignIn,
                    onFacebookSignIn: onFacebookSignIn
                )
            }
            .ignoresSafeArea(edges: .bottom)

            VStack {
                AuthBackButton(action: onBack)
                    .padding(.horizontal, AuthLayout.horizontalPadding)
                    .padding(.top, AuthLayout.backgroundBackButtonTopPadding)

                Spacer()
            }
        }
    }
}

#Preview {
    AuthView()
}
