//
//  SdkInitializationView.swift
//  Sandbox
//
//  Created by Евгения Григорович on 11/06/2025.
//

import SwiftUI
import Bidon

struct SdkInitializationView: View {
    @State private var status: String = "Idle"
    @State private var logs: [String] = []

    private let interstitial = Interstitial()

    var body: some View {
        Form {
            Section(header: Text("SDK Initialization")) {
                Button("Initialize SDK") {
                    BidonSdk.registerDefaultAdapters()
                    status = "Initializing..."
                    BidonSdk.initialize(appKey: Constants.Bidon.appKey) {
                        status = "Initialized ✅"
                        logs.append("✔️ SDK initialized")
                    }
                }
            }
            Section(header: Text("Main Screen")) {
                NavigationLink(destination: HomeView()) {
                    Text("Show main screen")
                }
            }

            Section(header: Text("Test Main Screen for muliple load")) {
                NavigationLink(destination: InterstitialAdDemoView()) {
                    Text("Interstitial")
                }

                NavigationLink(destination: RewardedAdDemoView()) {
                    Text("Rewarded")
                }

                NavigationLink(destination: BannerAdDemoView()) {
                    Text("Banner")
                }
            }
            
            Section(header: Text("Status")) {
                Text(status)
            }

            Section(header: Text("Logs")) {
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(logs.indices, id: \.self) {
                            Text(logs[$0]).font(.footnote)
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .navigationTitle("Manual Init")
    }
}
