//
//  ContentView.swift
//  Sandbox
//
//  Created by Bidon Team on 04.08.2022.
//

import SwiftUI
import Bidon


struct ContentView: View {
    @StateObject var vm = ContentViewModel()

    var body: some View {
        if vm.isInitialized {
            HomeView()
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .trailing)
                    )
                )
                .zIndex(1)
        } else {
            InitializationView()
                .environmentObject(vm.initializationViewModel)
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 1.2),
                        removal: .move(edge: .trailing)
                    )
                )
                .zIndex(1)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
