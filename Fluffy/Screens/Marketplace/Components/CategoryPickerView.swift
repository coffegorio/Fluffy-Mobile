//
//  CategoryPickerView.swift
//  Fluffy
//

import SwiftUI

struct CategoryPickerView: View {
    let activeCategory: ListingCategory
    let onChange: (ListingCategory) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(ListingCategory.allCases) { category in
                    Button {
                        onChange(category)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: category.systemImage)
                                .font(.system(size: 12, weight: .bold))
                                .accessibilityHidden(true)
                            Text(category.titleKey)
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(activeCategory == category ? .white : AppTheme.secondaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            activeCategory == category
                                ? category.tint
                                : AppTheme.surface.opacity(0.56),
                            in: Capsule()
                        )
                        .overlay {
                            Capsule()
                                .stroke(.white.opacity(activeCategory == category ? 0.28 : 0.72), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
}
