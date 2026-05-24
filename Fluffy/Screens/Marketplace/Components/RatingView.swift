//
//  RatingView.swift
//  Fluffy
//

import SwiftUI

struct RatingView: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.yellow)

            Text(rating, format: .number.precision(.fractionLength(1)))
                .font(.system(size: 12, weight: .bold))
        }
    }
}
