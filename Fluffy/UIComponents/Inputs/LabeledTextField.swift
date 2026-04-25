//
//  LabeledTextField.swift
//  Fluffy
//
//  Created by Egor Matveev on 24.04.2026.
//

import SwiftUI

/// Текстовое поле с подписью сверху и иконкой слева внутри поля.
struct LabeledTextField: View {

    let label: String
    let placeholder: String
    let icon: String
    var isSecure: Bool = false

    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: LabeledTextFieldLayout.labelSpacing) {
            Text(label)
                .font(.system(size: LabeledTextFieldLayout.labelSize, weight: .medium))
                .foregroundStyle(.primary)

            HStack(spacing: LabeledTextFieldLayout.iconSpacing) {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .frame(width: LabeledTextFieldLayout.iconSize, height: LabeledTextFieldLayout.iconSize)

                if isSecure {
                    SecureField(placeholder, text: $text)
                        .font(.system(size: LabeledTextFieldLayout.inputSize))
                } else {
                    TextField(placeholder, text: $text)
                        .font(.system(size: LabeledTextFieldLayout.inputSize))
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .padding(.horizontal, LabeledTextFieldLayout.fieldHorizontalPadding)
            .frame(height: LabeledTextFieldLayout.fieldHeight)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: LabeledTextFieldLayout.fieldCornerRadius))
        }
    }
}

private enum LabeledTextFieldLayout {
    static let labelSize: CGFloat = 14
    static let labelSpacing: CGFloat = 8
    static let iconSize: CGFloat = 20
    static let iconSpacing: CGFloat = 10
    static let inputSize: CGFloat = 16
    static let fieldHeight: CGFloat = 52
    static let fieldHorizontalPadding: CGFloat = 14
    static let fieldCornerRadius: CGFloat = 12
}

#Preview {
    @Previewable @State var email = ""
    @Previewable @State var password = ""

    VStack(spacing: 16) {
        LabeledTextField(
            label: "Email",
            placeholder: "sarah.j@email.com",
            icon: "envelope",
            text: $email
        )
        LabeledTextField(
            label: "Password",
            placeholder: "••••••••••",
            icon: "lock",
            isSecure: true,
            text: $password
        )
    }
    .padding()
}
