//
//  BannerLayoutHelper.swift
//  Bidon
//
//  Created by Stas Kochkin on 05.09.2023.
//

import Foundation
import UIKit


struct BannerLayoutHelper {
    struct Positioning {
        var constraints: [NSLayoutConstraint]
        var transform: CGAffineTransform
        var anchorPoint: CGPoint
    }
    
    enum Position {
        case fixed(BannerPosition)
        case custom(CGPoint, CGFloat, CGPoint)
    }
    
    var format: BannerFormat
    var position: Position
    
    func positioning(
        children view: UIView,
        superview: UIView
    ) -> Positioning {
        switch position {
        case .fixed(let bannerPosition):
            return fixexPositioning(
                position: bannerPosition,
                children: view,
                superview: superview
            )
        case .custom(let point, let angle, let anchor):
            return Positioning(
                constraints: sizeContraints(
                    children: view,
                    superview: superview
                ) + [
                    view.centerXAnchor.constraint(
                        equalTo: superview.leftAnchor,
                        constant: point.x
                    ),
                    view.centerYAnchor.constraint(
                        equalTo: superview.topAnchor,
                        constant: point.y
                    )
                ],
                transform: CGAffineTransform(rotationAngle: angle / 180 * .pi),
                anchorPoint: anchor
            )
        }
    }
    
    private func fixexPositioning(
        position: BannerPosition,
        children view: UIView,
        superview: UIView
    ) -> Positioning {
        switch position {
        case .horizontalBottom:
            return Positioning(
                constraints: sizeContraints(
                    children: view,
                    superview: superview
                ) + [
                    view.centerXAnchor.constraint(equalTo: superview.centerXAnchor),
                    view.bottomAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.bottomAnchor)
                ],
                transform: .identity,
                anchorPoint: CGPoint(x: 0.5, y: 0.5)
            )
        case .horizontalTop:
            return Positioning(
                constraints: sizeContraints(
                    children: view,
                    superview: superview
                ) + [
                    view.centerXAnchor.constraint(equalTo: superview.centerXAnchor),
                    view.topAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.topAnchor)
                ],
                transform: .identity,
                anchorPoint: CGPoint(x: 0.5, y: 0.5)
            )
        case .verticalLeft:
            return Positioning(
                constraints: sizeContraints(
                    children: view,
                    superview: superview
                ) + [
                    view.centerYAnchor.constraint(equalTo: superview.centerYAnchor),
                    view.leftAnchor.constraint(
                        equalTo: superview.safeAreaLayoutGuide.leftAnchor,
                        constant: -(format.preferredSize.width - format.preferredSize.height) * 0.5
                    )
                ],
                transform: CGAffineTransform(rotationAngle: -0.5 * .pi),
                anchorPoint: CGPoint(x: 0.5, y: 0.5)
            )
        case .verticalRight:
            return Positioning(
                constraints: sizeContraints(
                    children: view,
                    superview: superview
                ) + [
                    view.centerYAnchor.constraint(equalTo: superview.centerYAnchor),
                    view.rightAnchor.constraint(
                        equalTo: superview.safeAreaLayoutGuide.rightAnchor,
                        constant: (format.preferredSize.width - format.preferredSize.height) * 0.5
                    )
                ],
                transform: CGAffineTransform(rotationAngle: 0.5 * .pi),
                anchorPoint: CGPoint(x: 0.5, y: 0.5)
            )
        }
    }
    
    private func sizeContraints(
        children view: UIView,
        superview: UIView
    ) -> [NSLayoutConstraint] {
        switch format {
        case .adaptive:
            return [
                view.heightAnchor.constraint(equalToConstant: format.preferredSize.height),
                view.widthAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.widthAnchor)
            ]
        default:
            return [
                view.heightAnchor.constraint(equalToConstant: format.preferredSize.height),
                view.widthAnchor.constraint(equalToConstant: format.preferredSize.width)
            ]
        }
    }
}


extension BannerLayoutHelper.Position {
    init(position: BannerPosition) {
        self = .fixed(position)
    }
    
    init(
        point: CGPoint,
        angle: CGFloat,
        anchorPoint: CGPoint
    ) {
        self = .custom(point, angle, anchorPoint)
    }
}
