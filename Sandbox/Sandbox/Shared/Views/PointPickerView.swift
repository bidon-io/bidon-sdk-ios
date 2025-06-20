//
//  PointPickerView.swift
//  Sandbox
//
//  Created by Stas Kochkin on 06.09.2023.
//

import Foundation
import SwiftUI


struct PointPickerView: View {
    var size: CGSize

    @Binding var point: CGPoint

    @State var dragOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color(.systemGray5)
                .border(Color.accentColor, width: 1.5)
                .frame(
                    width: size.width,
                    height: size.height
                )
            Circle()
                .strokeBorder(Color.accentColor, lineWidth: 5)
                .background(Circle().fill(Color.accentColor.opacity(0.8)))
                .frame(width: 32, height: 32)
                .offset(dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let translation = CGSize(
                                width: max(-size.width * 0.5, min(size.width * 0.5, value.translation.width)),
                                height: max(-size.height * 0.5, min(size.height * 0.5, value.translation.height))
                            )
                            withAnimation(.interactiveSpring()) {
                                self.dragOffset = translation
                                self.point = CGPoint(
                                    x: floor(size.width * 0.5 + translation.width),
                                    y: floor(size.height * 0.5 + translation.height)
                                )
                            }
                        }
                )
        }
    }
}


struct PointPickerView_Previews: PreviewProvider {
    struct StatefullPointPickerView: View {
        @State var point: CGPoint = .zero

        var body: some View {
            VStack {
                Text(String(describing: point))
                PointPickerView(
                    size: DeviceFrame(scale: 0.3).size,
                    point: $point
                )
            }
        }
    }

    static var previews: some View {
        StatefullPointPickerView()
    }
}
