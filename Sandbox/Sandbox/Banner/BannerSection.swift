//
//  BannerSection.swift
//  Sandbox
//
//  Created by Bidon Team on 29.08.2022.
//

import Foundation
import SwiftUI
import Bidon


struct BannerAdSection: View {
    @EnvironmentObject var vm: BannerSectionViewModel
    
    var body: some View {
        Group {
            Section(header: Text("Banner")) {
                Stepper(
                    "Pricefloor: \(vm.pricefloor.pretty)",
                    value: $vm.pricefloor,
                    in: (0.0...100.0),
                    step: 0.1
                )
                
                Button(action: {
                    withAnimation {
                        vm.isLoading.toggle()
                    }
                }) {
                    HStack {
                        Text(vm.isLoading ? "Loading...": "Load")
                            .foregroundColor(!vm.isPresented || vm.isLoading ? .secondary : .primary)
                        Spacer()
                        if vm.isLoading {
                            ProgressView()
                        }
                    }
                }
                .adContextMenu(
                    vm.ad,
                    onWin: vm.notify(win:),
                    onLoss: vm.notify(loss:)
                )
                .disabled(!vm.isPresented || vm.isLoading)
                
                Button(action: {
                    withAnimation {
                        vm.isPresented.toggle()
                    }
                }) {
                    HStack {
                        Text(vm.isPresented ? "Hide": "Present")
                        Spacer()
                    }
                }
                
                NavigationLink("Events", destination: AdEventsList(events: vm.events))
                NavigationLink(
                    "Advanced",
                    destination: AdvancedBannerSettings(
                        format: $vm.format,
                        isAutorefreshing: $vm.isAutorefreshing,
                        autorefreshInterval: $vm.autorefreshInterval
                    )
                )
            }
        }
        .foregroundColor(.primary)
    }
}

extension BannerFormat: CaseIterable {
    public static var allCases: [BannerFormat] = [.adaptive, .banner, .leaderboard, .mrec]
}

