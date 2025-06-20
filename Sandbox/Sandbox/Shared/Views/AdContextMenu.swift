//
//  ContextMenu.swift
//  Sandbox
//
//  Created by Bidon Team on 06.04.2023.
//

import Foundation
import SwiftUI
import Bidon


struct AdContextMenuModifier: ViewModifier {
    var ad: Bidon.Ad?
    var onWin: (Bidon.Ad) -> ()
    var onLoss: (Bidon.Ad) -> ()

    func body(content: Content) -> some View {
        guard let ad = ad else {
            return AnyView(content)
        }

        if #available(iOS 16, *) {
            return AnyView(
                content.contextMenu(
                    menuItems: {
                        menuItems
                    },
                    preview: {
                        Text(ad.text)
                            .padding()
                    }
                )
            )
        } else {
            return AnyView(
                content.contextMenu {
                    menuItems
                }
            )
        }
    }

    @ViewBuilder
    var menuItems: some View {
        Button(action: { ad.map { onWin($0) } }) {
            Label("Notify Win", systemImage: "paperplane.fill")
        }

        Button(action: { ad.map { onLoss($0) } }) {
            Label("Notify Loss", systemImage: "paperplane")
        }
    }
}


extension View {
    func adContextMenu(
        _ ad: Bidon.Ad?,
        onWin: @escaping (Bidon.Ad) -> (),
        onLoss: @escaping (Bidon.Ad) -> ()
    ) -> some View {
        return modifier(
            AdContextMenuModifier(
                ad: ad,
                onWin: onWin,
                onLoss: onLoss
            )
        )
    }
}
