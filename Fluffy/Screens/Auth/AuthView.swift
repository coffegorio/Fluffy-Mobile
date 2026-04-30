//
//  AuthView.swift
//  Fluffy
//
//  Created by Egor Matveev on 24.04.2026.
//

import Observation
import SwiftUI

struct AuthView: View {
    @State var viewModel: AuthViewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            PawBackgroundView()

            VStack {
                Spacer()

                AuthPanel(
                    email: $viewModel.email,
                    password: $viewModel.password,
                    onSignIn: viewModel.signInTapped,
                    onForgotPassword: viewModel.forgotPasswordTapped,
                    onSignUp: viewModel.signUpTapped,
                    onGoogleSignIn: viewModel.googleSignInTapped,
                    onFacebookSignIn: viewModel.facebookSignInTapped
                )
            }
            .ignoresSafeArea(edges: .bottom)

            VStack {
                CircleIconButton(
                    title: "auth_back_button",
                    systemImage: "chevron.left",
                    action: viewModel.backTapped
                )
                    .padding(.horizontal, AuthLayout.horizontalPadding)
                    .padding(.top, AuthLayout.backgroundBackButtonTopPadding)

                Spacer()
            }
        }
    }
}

#Preview {
    AuthView(
        viewModel: AuthViewModel(
            coordinator: nil,
            authService: MockAuthService()
        )
    )
}
