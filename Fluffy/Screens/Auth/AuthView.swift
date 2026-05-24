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
                    code: $viewModel.code,
                    step: viewModel.step,
                    isLoading: viewModel.isLoading,
                    isPrimaryActionEnabled: viewModel.isPrimaryActionEnabled,
                    primaryButtonTitle: viewModel.primaryButtonTitle,
                    errorMessage: viewModel.errorMessage,
                    onPrimaryAction: viewModel.primaryActionTapped
                )
            }
            .ignoresSafeArea(.container, edges: .bottom)

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
        .navigationBarBackButtonHidden()
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
