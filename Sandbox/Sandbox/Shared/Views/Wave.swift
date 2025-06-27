//
//  Wave.swift
//  Sandbox
//
//  Created by Bidon Team on 12.09.2022.
//

import Foundation
import SwiftUI


struct Wave: Shape {
    var offset: Angle
    var percent: Double

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(offset.degrees, percent) }
        set {
            offset = Angle(degrees: newValue.first)
            percent = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let waveHeight = 0.025 * rect.height
        let yOffset = CGFloat(1 - percent) * (rect.height - 4 * waveHeight) + 2 * waveHeight
        let startAngle = offset
        let endAngle = offset + Angle(degrees: 360)

        p.move(
            to: CGPoint(
                x: 0,
                y: yOffset + waveHeight * CGFloat(sin(offset.radians))
            )
        )

        for angle in stride(from: startAngle.degrees, through: endAngle.degrees, by: 10) {
            let x = CGFloat((angle - startAngle.degrees) / 360) * rect.width
            p.addLine(
                to: CGPoint(
                    x: x,
                    y: yOffset + waveHeight * CGFloat(sin(Angle(degrees: angle).radians))
                )
            )
        }

        p.addLine(to: CGPoint(x: rect.width, y: rect.height))
        p.addLine(to: CGPoint(x: 0, y: rect.height))
        p.closeSubpath()

        return p
    }
}
