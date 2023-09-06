//
//  BannerPositionPickerView.swift
//  Sandbox
//
//  Created by Stas Kochkin on 06.09.2023.
//

import Foundation
import SwiftUI
import Bidon


struct BannerPositionPickerView: View {
    enum PositioningStyle: String {
        case fixed
        case custom
    }
    
    @State var positioningStyle = PositioningStyle.fixed {
        didSet { updatePosition() }
    }
    
    @State var fixedPosition: BannerPosition? {
        didSet { updatePosition() }
    }
    
    @State var customPosition: CGPoint? {
        didSet { updatePosition() }
    }
    
    @State var customRotationAngle: CGFloat = 0.0 {
        didSet { updatePosition() }
    }
    
    @State var customAnchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5) {
        didSet { updatePosition() }
    }
        
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                Picker("Positioning", selection: $positioningStyle) {
                    Text("Fixed").tag(PositioningStyle.fixed)
                    Text("Custom").tag(PositioningStyle.custom)
                }
                .padding(.horizontal)
                .pickerStyle(.segmented)
                
                switch positioningStyle {
                case .fixed:
                    List {
                        ForEach(BannerPosition.allCases, id: \.rawValue) { position in
                            Button(action: {
                                withAnimation {
                                    self.fixedPosition = position
                                }
                            }) {
                                HStack {
                                    Text(position.title)
                                    Spacer()
                                    if self.fixedPosition == position {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                        }
                    }
                case .custom:
                    List {
                        Section(header: Text("Position")) {
                            HStack {
                                Text("Position is \(customPosition.map { String(describing: $0) } ?? "-")")
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        customPosition = nil
                                    }
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                            
                            PointPickerView(
                                size: DeviceFrame(scale: 0.3).size,
                                point: Binding(
                                    get: {
                                        CGPoint(
                                            x: customPosition.map { $0.x * 0.3 } ?? 0,
                                            y: customPosition.map { $0.y * 0.3 } ?? 0
                                        )
                                    },
                                    set: { point in
                                        customPosition = CGPoint(
                                            x: floor(point.x / 0.3),
                                            y: floor(point.y / 0.3)
                                        )
                                    }
                                )
                            )
                            .frame(maxWidth: .infinity)
                        }
                        
                        Section(header: Text("Anchor Point")) {
                            HStack {
                                Text("Anchor point is " + String(describing: customAnchorPoint))
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        customAnchorPoint = CGPoint(x: 0.5, y: 0.5)
                                    }
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                            
                            PointPickerView(
                                size: CGSize(width: 150, height: 150),
                                point: Binding(
                                    get: {
                                        CGPoint(
                                            x: customAnchorPoint.x * 150,
                                            y: customAnchorPoint.y * 150
                                        )
                                    },
                                    set: { point in
                                        customAnchorPoint = CGPoint(
                                            x: round(point.x / 15) / 10.0,
                                            y: round(point.y / 15) / 10.0
                                        )
                                    }
                                )
                            )
                            .frame(maxWidth: .infinity)
                        }
                        
                        Section(header: Text("Rotation Angle")) {
                            Slider(
                                value: Binding(
                                    get: { customRotationAngle },
                                    set: { customRotationAngle = floor($0) }
                                ),
                                in: (-180...180)
                            )
                            Text("Rotation angle is \(Int(customRotationAngle))°")
                        }
                    }
                }
            }
        }
    }
    
    func updatePosition() {
        switch positioningStyle {
        case .custom:
            BannerProvider.shared.setCustomPosition(
                customPosition ?? .zero,
                rotationAngleDegrees: customRotationAngle,
                anchorPoint: customAnchorPoint
            )
        case .fixed:
            BannerProvider.shared.setFixedPosition(fixedPosition ?? .horizontalBottom)
        }
    }
}


extension BannerPosition: CaseIterable {
    public static var allCases: [BannerPosition] = [
        .horizontalTop,
        .horizontalBottom,
        .verticalLeft,
        .verticalRight
    ]
    
    var title: String {
        switch self {
        case .horizontalTop: return "Horizontal Top"
        case .horizontalBottom: return "Horizontal Bottom"
        case .verticalLeft: return "Vertical Left"
        case .verticalRight: return "Vertical Right"
        }
    }
}
