//
//  AuthForm.swift
//  Fluffy
//
//  Created by Egor Matveev on 24.04.2026.
//

import SwiftUI

struct AuthForm: View {
    @Binding var email: String
    @Binding var password: String

    let onForgotPassword: () -> Void

    @ScaledMetric private var forgotPasswordSize = AuthLayout.forgotPasswordSize

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LabeledTextField(
                label: String(localized: "auth_email_label"),
                placeholder: String(localized: "auth_email_placeholder"),
                icon: "envelope",
                text: $email
            )

            LabeledTextField(
                label: String(localized: "auth_password_label"),
                placeholder: String(localized: "auth_password_placeholder"),
                icon: "lock",
                isSecure: true,
                text: $password
            )
            .padding(.top, AuthLayout.fieldSpacing)

            HStack {
                Spacer()

                Button(action: onForgotPassword) {
                    Text("auth_forgot_password")
                        .font(.system(size: forgotPasswordSize, weight: .medium))
                        .foregroundStyle(.accent)
                }
            }
            .padding(.top, AuthLayout.forgotPasswordTopPadding)
        }
    }
}
