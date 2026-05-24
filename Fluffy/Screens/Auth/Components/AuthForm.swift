//
//  AuthForm.swift
//  Fluffy
//
//  Created by Egor Matveev on 24.04.2026.
//

import SwiftUI

struct AuthForm: View {
    @Binding var email: String
    @Binding var code: String

    let step: AuthStep

    var body: some View {
        VStack(alignment: .leading, spacing: AuthLayout.fieldSpacing) {
            switch step {
            case .email:
                LabeledTextField(
                    label: String(localized: "auth_email_label"),
                    placeholder: String(localized: "auth_email_placeholder"),
                    icon: "envelope",
                    accessibilityIdentifier: "auth_email_field",
                    text: $email
                )
            case .code:
                VStack(alignment: .leading, spacing: 12) {
                    Text("auth_code_instruction")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)

                    LabeledTextField(
                        label: String(localized: "auth_code_label"),
                        placeholder: String(localized: "auth_code_placeholder"),
                        icon: "number",
                        keyboardType: .numberPad,
                        accessibilityIdentifier: "auth_code_field",
                        text: $code
                    )
                }
            }
        }
    }
}
