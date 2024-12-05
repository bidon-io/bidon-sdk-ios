//
//  HomeView.swift
//  Sandbox
//
//  Created by Bidon Team on 12.08.2022.
//

import Foundation
import SwiftUI
import Bidon
import Combine


struct HomeView: View {
    @StateObject var vm = HomeViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.secondarySystemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    List {
                        InterstitialSection()
                        RewardedAdSection()
                        BannerAdSection()
                            .environmentObject(vm.banner)
                    }
                    
                    if vm.isBannerPresented {
                        Divider()
                        
                        ZStack {
                            AnyAdBannerWrapperView(
                                format: vm.bannerSettings.format,
                                isAutorefreshing: vm.bannerSettings.isAutorefreshing,
                                autorefreshInterval: vm.bannerSettings.autorefreshInterval,
                                pricefloor: vm.bannerSettings.pricefloor,
                                auctionKey: vm.bannerSettings.auctionKey,
                                onEvent: { event in
                                    if event.title == "Bidon did load ad" {
                                        $vm.bannerView.wrappedValue.show()
                                    }
                                    vm.banner.receive(event: event)
                                },
                                banner: $vm.bannerView.wrappedValue,
                                ad: $vm.banner.ad,
                                isLoading: $vm.banner.isLoading,
                                wasLoaded: $vm.banner.wasLoaded
                            )
                            
                            if vm.isBannerLoading {
                                ActivityPlaceholder()
                            }
                        }
                        .frame(height: vm.bannerHeight)
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle(title)
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private var title: Text {
        let mediation: String
        
        switch AdServiceProvider().service.mediation {
        case .appodeal: mediation = "Appodeal + "
        case .none: mediation = "Raw "
        }
        
        return Text(mediation + "Bidon v\(BidonSdk.sdkVersion)")
    }
}


final class HomeViewModel: ObservableObject {
    struct BannerSettings {
        var format: AdBannerWrapperFormat
        var isAutorefreshing: Bool
        var autorefreshInterval: TimeInterval
        var pricefloor: Price
        var auctionKey: AuctionKey?
    }
    
    lazy var bannerView = BannerView(frame: .zero, auctionKey: bannerSettings.auctionKey)

    @Published var banner = BannerSectionViewModel()
    
    @Published var isBannerPresented: Bool = false
    @Published var isBannerLoading: Bool = false
    @Published var bannerHeight: CGFloat = 0
    @Published var bannerSettings = BannerSettings(
        format: .banner,
        isAutorefreshing: false,
        autorefreshInterval: 15,
        pricefloor: 0.1,
        auctionKey: ""
    )
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        subscribe()
    }
    
    func subscribe() {
        banner.$isPresented.sink { [unowned self] in
            self.isBannerPresented = $0
        }
        .store(in: &cancellables)
        
        banner.$format
            .map { $0.preferredSize.height }
            .sink { [unowned self] height in
                withAnimation {
                    self.bannerHeight = height
                }
            }
            .store(in: &cancellables)
        
        banner
            .$isLoading
            .delay(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [unowned self] isBannerLoading in
                withAnimation {
                    self.isBannerLoading = isBannerLoading
                }
            }
            .store(in: &cancellables)
        
        let paramsOne = Publishers
            .CombineLatest3(
                banner.$format, 
                banner.$isAutorefreshing,
                banner.$autorefreshInterval
            )
                
        let paramsTwo = Publishers
            .CombineLatest(
                banner.$pricefloor,
                banner.$auctionKey
            )
        
        paramsOne.combineLatest(paramsTwo)
            .sink { [unowned self] in
                self.bannerSettings = BannerSettings(
                    format: $0.0.0,
                    isAutorefreshing: $0.0.1,
                    autorefreshInterval: $0.0.2,
                    pricefloor: $0.1.0,
                    auctionKey: $0.1.1
                )
            }
            .store(in: &cancellables)
    }
}
