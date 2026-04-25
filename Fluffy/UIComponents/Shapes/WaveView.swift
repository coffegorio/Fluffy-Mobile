//
//  WaveView.swift
//  Fluffy
//
//  Created by Egor Matveev on 23.04.2026.
//

import SwiftUI

struct AuthWaveShape: Shape {
    static let startY: CGFloat = 90
    static let endY: CGFloat = 150
    static let control1Y: CGFloat = 20
    static let control2Y: CGFloat = 185

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 0, y: Self.startY))
        path.addCurve(
            to: CGPoint(x: rect.width, y: Self.endY),
            control1: CGPoint(x: rect.width * 0.28, y: Self.control1Y),
            control2: CGPoint(x: rect.width * 0.72, y: Self.control2Y)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
    }
}

struct WelcomeWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 0, y: rect.height * 0.15))
        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.35),
            control1: CGPoint(x: rect.width * 0.45, y: -rect.height * 0.05),
            control2: CGPoint(x: rect.width * 0.80, y: rect.height * 0.32)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
    }
}
