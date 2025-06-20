//
//  OverlayProgressView.swift
//  Sandbox
//
//  Created by Bidon Team on 05.09.2022.
//

import Foundation
import SwiftUI


struct AppProgressView: View {
    @State private var percent: CGFloat = 0
    @State private var offset: CGFloat = 0

    var body: some View {
        ZStack {
            Wave(
                offset: .degrees(-offset),
                percent: percent
            )
            .fill(Color.accentColor.opacity(0.8))
            .frame(width: 44, height: 64)

            Wave(
                offset: .degrees(offset),
                percent: percent
            )
            .fill(Color.accentColor.opacity(0.8))
            .frame(width: 44, height: 64)
        }
        .mask(
            Image("BidonMask")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 44, height: 64)
        )
        .frame(width: 44, height: 64)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.75).repeatForever(autoreverses: true)) {
                percent = 1
                offset = 180
            }
        }
        .transition(.identity)
    }
}



struct AppProgressView_Previews: PreviewProvider {
    static var previews: some View {
        AppProgressView()
    }
}
