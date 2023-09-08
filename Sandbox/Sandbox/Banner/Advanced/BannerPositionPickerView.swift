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
    @ObservedObject var bannerProviderReference = BannerProviderReference.shared
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                Picker("Positioning", selection: $bannerProviderReference.positioningStyle) {
                    Text("Fixed").tag(BannerProviderReference.PositioningStyle.fixed)
                    Text("Custom").tag(BannerProviderReference.PositioningStyle.custom)
                }
                .padding(.horizontal)
                .pickerStyle(.segmented)
                
                switch bannerProviderReference.positioningStyle {
                case .fixed:
                    List {
                        ForEach(BannerPosition.allCases, id: \.rawValue) { position in
                            Button(action: {
                                withAnimation {
                                    self.bannerProviderReference.fixedPosition = position
                                }
                            }) {
                                HStack {
                                    Text(position.title)
                                    Spacer()
                                    if self.bannerProviderReference.fixedPosition == position {
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
                                Text("Position is \(bannerProviderReference.customPosition.map { String(describing: $0) } ?? "-")")
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        bannerProviderReference.customPosition = nil
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
                                            x: bannerProviderReference.customPosition.map { $0.x * 0.3 } ?? 0,
                                            y: bannerProviderReference.customPosition.map { $0.y * 0.3 } ?? 0
                                        )
                                    },
                                    set: { point in
                                        bannerProviderReference.customPosition = CGPoint(
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
                                Text("Anchor point is " + String(describing: bannerProviderReference.customAnchorPoint))
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        bannerProviderReference.customAnchorPoint = CGPoint(x: 0.5, y: 0.5)
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
                                            x: bannerProviderReference.customAnchorPoint.x * 150,
                                            y: bannerProviderReference.customAnchorPoint.y * 150
                                        )
                                    },
                                    set: { point in
                                        bannerProviderReference.customAnchorPoint = CGPoint(
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
                                    get: { bannerProviderReference.customRotationAngle },
                                    set: { bannerProviderReference.customRotationAngle = floor($0) }
                                ),
                                in: (-180...180)
                            )
                            Text("Rotation angle is \(Int(bannerProviderReference.customRotationAngle))°")
                        }
                    }
                }
            }
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
