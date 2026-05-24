//
//  ListingBadge.swift
//  Fluffy
//

import SwiftUI

struct ListingBadge: View {
    let category: ListingCategory

    var body: some View {
        Text(category.titleKey)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(category.tint)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(category.softTint, in: Capsule())
    }
}
