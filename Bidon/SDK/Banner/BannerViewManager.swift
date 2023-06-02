//
//  AdContainerViewManager.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 08.07.2022.
//

import Foundation
import UIKit



protocol BannerViewManagerDelegate: AnyObject {
    func viewManager(_ viewManager: BannerViewManager, didRecordImpression ad: Ad)
    func viewManager(_ viewManager: BannerViewManager, didRecordClick ad: Ad)
    func viewManager(_ viewManager: BannerViewManager, willPresentModalView ad: Ad)
    func viewManager(_ viewManager: BannerViewManager, didDismissModalView ad: Ad)
    func viewManager(_ viewManager: BannerViewManager, willLeaveApplication ad: Ad)
}


final internal class BannerViewManager: NSObject {
    static var impressionKey: UInt8 = 0
    
    @Injected(\.networkManager)
    private var networkManager: NetworkManager
    
    @Injected(\.sdk)
    private var sdk: Sdk
    
    private lazy var viewabilityTracker = Viewability.Tracker()
    
    weak var container: UIView?
    
    private var _impression: AdViewImpression? {
        container?
            .subviews
            .compactMap { $0 as? AdViewContainer }
            .first?
            .impression
    }
    
    var impression: Impression? {
        _impression
    }
    
    var bid: AdViewBid? {
        return _impression?.bid
    }
    
    weak var delegate: BannerViewManagerDelegate?
    
    var extras: [String: AnyHashable] = [:]
    
    func present(
        bid: AdViewBid,
        view: AdViewContainer,
        viewContext: AdViewContext
    ) {
        guard
            let container = container,
            !container.subviews.contains(view)
        else { return }
        
        bid.provider.adViewDelegate = self
        
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        container.addSubview(view)
        
        let constraints: [NSLayoutConstraint]
        
        if view.isAdaptive {
            constraints = [
                view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                view.topAnchor.constraint(equalTo: container.topAnchor),
                view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ]
        } else {
            let size = viewContext.format.preferredSize
            
            constraints = [
                view.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                view.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                view.widthAnchor.constraint(equalToConstant: size.width),
                view.heightAnchor.constraint(equalToConstant: size.height)
            ]
        }
        
        NSLayoutConstraint.activate(constraints)
        
        UIView.animate(
            withDuration: 0.25,
            delay: 0, options: .curveEaseInOut,
            animations: {
                container
                    .subviews
                    .filter { $0 is AdViewContainer && $0 !== view }
                    .forEach { $0.alpha = 0 }
                view.alpha = 1
            }
        ) { [weak self] _ in
            container
                .subviews
                .filter { $0 !== view }
                .compactMap { $0 as? AdViewContainer }
                .forEach { $0.destroy() }
            
            self?.viewabilityTracker.startTracking(view: view) { [weak self] in
                self?.viewabilityTracker.finishTracking()
                self?.trackImpression(adView: view)
                
                bid.provider.didTrackImpression(opaque: bid.ad)
            }
        }
        
        view.impression = AdViewImpression(
            bid: bid,
            format: viewContext.format
        )
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(didReceiveTap))
        recognizer.delegate = self
        view.addGestureRecognizer(recognizer)
    }
    
    func hide() {
        viewabilityTracker.finishTracking()
        container?
            .subviews
            .compactMap { $0 as? AdViewContainer }
            .forEach { $0.destroy() }
    }
    
    private func sendImpressionIfNeeded(
        _ impression: inout AdViewImpression,
        path: Route
    ) {
        guard impression.isTrackingAllowed(path) else { return }
        
        let request = ImpressionRequest { (builder: AdViewImpressionRequestBuilder) in
            builder.withEnvironmentRepository(sdk.environmentRepository)
            builder.withTestMode(sdk.isTestMode)
            builder.withExt(extras, sdk.extras)
            builder.withImpression(impression)
            builder.withContext(AdViewAucionContext(format: impression.format))
            builder.withPath(path)
        }
        
        networkManager.perform(request: request) { result in
            Logger.debug("Sent impression action '\(path)' with result: \(result)")
        }
        
        impression.markTrackedIfNeeded(path)
    }
    
    private func trackImpression(adView: AdViewContainer) {
        guard var impression = adView.impression else { return }
        
        sendImpressionIfNeeded(&impression, path: .show)
                
        let ad = AdContainer(impression: impression)
        delegate?.viewManager(self, didRecordImpression: ad)
        
        adView.impression = impression
    }
    
    @objc private
    func didReceiveTap(_ recognizer: UITapGestureRecognizer) {
        guard
            let adView = recognizer.view as? AdViewContainer,
            var impression = adView.impression
        else { return }
        
        sendImpressionIfNeeded(&impression, path: .click)
        
        let ad = AdContainer(impression: impression)
        delegate?.viewManager(self, didRecordClick: ad)
        
        adView.impression = impression
    }
}


extension BannerViewManager: DemandProviderAdViewDelegate {
    func providerWillPresentModalView(
        _ provider: any AdViewDemandProvider,
        adView: AdViewContainer
    ) {
        guard let impression = adView.impression else { return }
        
        let ad = AdContainer(impression: impression)
        delegate?.viewManager(self, willPresentModalView: ad)
    }
    
    func providerDidDismissModalView(
        _ provider: any AdViewDemandProvider,
        adView: AdViewContainer
    ) {
        guard let impression = adView.impression else { return }
        
        let ad = AdContainer(impression: impression)
        delegate?.viewManager(self, didDismissModalView: ad)
    }
    
    func providerWillLeaveApplication(
        _ provider: any AdViewDemandProvider,
        adView: AdViewContainer
    ) {
        guard let impression = adView.impression else { return }
        
        let ad = AdContainer(impression: impression)
        delegate?.viewManager(self, willLeaveApplication: ad)
    }
}


extension BannerViewManager: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
}


private extension AdViewContainer {
    var impression: AdViewImpression? {
        get { objc_getAssociatedObject(self, &BannerViewManager.impressionKey) as? AdViewImpression }
        set { objc_setAssociatedObject(self, &BannerViewManager.impressionKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    func destroy() {
        impression = nil
        removeFromSuperview()
    }
}
