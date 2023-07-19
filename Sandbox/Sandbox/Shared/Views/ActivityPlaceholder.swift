//
//  ActivityPlaceholder.swift
//  Sandbox
//
//  Created by Bidon Team on 12.04.2023.
//

import Foundation
import SwiftUI


struct ActivityPlaceholder: View {
    @State var isAnimating: Bool = false
    
    var body: some View {
        VisualEffectView(
            effect: UIBlurEffect(style: .regular)
        )
        .opacity(isAnimating ? 1 : 0)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 0.75)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}


struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    
    func makeUIView(
        context: UIViewRepresentableContext<Self>
    ) -> UIVisualEffectView {
        UIVisualEffectView()
    }
    
    func updateUIView(
        _ uiView: UIVisualEffectView,
        context: UIViewRepresentableContext<Self>
    ) {
        uiView.effect = effect
    }
}
