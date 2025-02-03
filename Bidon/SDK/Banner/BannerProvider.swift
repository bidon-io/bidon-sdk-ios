//
//  BannerProvider.swift
//  Bidon
//
//  Created by Stas Kochkin on 04.09.2023.
//

import Foundation
import UIKit


@objc(BDNBannerPosition)
public enum BannerPosition: Int {
    case horizontalTop = 0
    case horizontalBottom
    case verticalLeft
    case verticalRight
}


@objc(BDNBannerProvider)
public final class BannerProvider:  NSObject, AdObject {
    @objc public var isReady: Bool {
        bannerView.isReady
    }
    
    @objc public var isShowing: Bool {
        bannerView.superview != nil
    }
    
    @objc public var extras: [String : AnyHashable] {
        bannerView.extras
    }
    
    @objc public weak var delegate: AdObjectDelegate?
    
    @objc public var format: BannerFormat = .banner {
        didSet {
            bannerView.format = format
            layoutHelper.format = format
            layoutBannerView()
        }
    }
    
    @objc public var adSize: CGSize {
        return format.preferredSize
    }
    
    @objc public weak var rootViewController: UIViewController? {
        didSet {
            bannerView.rootViewController = rootViewController
        }
    }
    
    private lazy var bannerView: BannerView = {
        let bannerView = BannerView(frame: .zero, auctionKey: auctionKey)
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        bannerView.delegate = self
        
        return bannerView
    }()
    
    private let auctionKey: String?
    
    private lazy var constraintsHashTable = NSHashTable<NSLayoutConstraint>(options: .weakMemory)
    
    private var layoutHelper = BannerLayoutHelper(
        format: .banner,
        position: .fixed(.horizontalBottom)
    )
    
    @objc
    public init(auctionKey: String? = nil) {
        self.auctionKey = auctionKey
        
        super.init()
    }
    
    @objc public func notifyWin() {
        bannerView.notifyWin()
    }
    
    @objc public func notifyLoss(
        external demandId: String,
        price: Price
    ) {
        bannerView.notifyLoss(
            external: demandId,
            price: price
        )
    }
    
    @objc public func setExtraValue(
        _ value: AnyHashable?,
        for key: String
    ) {
        bannerView.setExtraValue(
            value,
            for: key
        )
    }
    
    @objc public func setCustomPosition(
        _ position: CGPoint,
        rotationAngleDegrees: CGFloat = 0,
        anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)
    ) {
        layoutHelper.position = BannerLayoutHelper.Position(point: position, angle: rotationAngleDegrees, anchorPoint: anchorPoint)
        layoutBannerView()
    }
    
    @objc public func setFixedPosition(_ posistion: BannerPosition) {
        layoutHelper.position = BannerLayoutHelper.Position(position: posistion)
        layoutBannerView()
    }
    
    @objc public func loadAd(
        with pricefloor: Price = .zero
    ) {
        if bannerView.isReady, let ad = bannerView.ad {
            #warning("FIX IT")
            delegate?.adObject(self, didLoadAd: ad, auctionInfo: DefaultAuctionInfo())
        } else {
            bannerView.loadAd(with: pricefloor, auctionKey: auctionKey)
        }
    }
    
    @objc public func show() {
        guard
            let view = rootViewController?.view ??
                UIApplication.shared.bd.topViewcontroller?.view
        else {
            delegate?.adObject?(
                self,
                didFailToPresentAd: SdkError.unableToFindRootViewController
            )
            return
        }
        
        if !bannerView.isReady && bannerView.subviews.isEmpty {
            delegate?.adObject?(
                self,
                didFailToPresentAd: SdkError.message("Banner ad is not ready and will be presented after loading")
            )
        }
        
        bannerView.removeFromSuperview()
        view.addSubview(bannerView)
        
        layoutBannerView()
    }
    
    @objc public func hide() {
        bannerView.removeFromSuperview()
    }
    
    private func layoutBannerView() {
        guard let superview = bannerView.superview else { return }
        
        let positioning = layoutHelper.positioning(
            children: bannerView,
            superview: superview
        )
        
        bannerView.setAnchorPoint(positioning.anchorPoint)
        bannerView.transform = positioning.transform
        
        NSLayoutConstraint.deactivate(constraintsHashTable.allObjects)
        NSLayoutConstraint.activate(positioning.constraints)
        
        constraintsHashTable.removeAllObjects()
        
        positioning.constraints.forEach(constraintsHashTable.add)
    }
}


extension BannerProvider: AdViewDelegate {
    public func adView(
        _ adView: UIView & AdView,
        willPresentScreen ad: Ad
    ) {}
    
    public func adView(
        _ adView: UIView & AdView,
        didDismissScreen ad: Ad
    ) {}
    
    public func adView(
        _ adView: UIView & AdView,
        willLeaveApplication ad: Ad
    ) {}
    
    public func adObject(
        _ adObject: AdObject,
        didLoadAd ad: Ad,
        auctionInfo: AuctionInfo
    ) {
        delegate?.adObject(self, didLoadAd: ad, auctionInfo: auctionInfo)
    }
    
    public func adObject(
        _ adObject: AdObject,
        didFailToLoadAd error: Error,
        auctionInfo: AuctionInfo
    ) {
        delegate?.adObject(
            self,
            didFailToLoadAd: error, auctionInfo: auctionInfo
        )
    }
    
    public func adObject(
        _ adObject: AdObject,
        didFailToPresentAd error: Error
    ) {
        delegate?.adObject?(
            self,
            didFailToPresentAd: error
        )
    }
    
    public func adObject(
        _ adObject: AdObject,
        didExpireAd ad: Ad
    ) {
        delegate?.adObject?(
            self,
            didExpireAd: ad
        )
    }
    
    public func adObject(
        _ adObject: AdObject,
        didRecordImpression ad: Ad
    ) {
        delegate?.adObject?(
            self,
            didRecordImpression: ad
        )
    }
    
    public func adObject(
        _ adObject: AdObject,
        didRecordClick ad: Ad
    ) {
        delegate?.adObject?(
            self,
            didRecordClick: ad)
    }
    
    public func adObject(
        _ adObject: AdObject,
        didPay revenue: AdRevenue,
        ad: Ad
    ) {
        delegate?.adObject?(
            self,
            didPay: revenue,
            ad: ad
        )
    }
}


extension BannerView {
    func setAnchorPoint(_ point: CGPoint) {
        if #available(iOS 16, *) {
            self.anchorPoint = point
        } else {
            var newPoint = CGPoint(x: bounds.size.width * point.x, y: bounds.size.height * point.y)
            var oldPoint = CGPoint(x: bounds.size.width * layer.anchorPoint.x, y: bounds.size.height * layer.anchorPoint.y);
            
            newPoint = newPoint.applying(transform)
            oldPoint = oldPoint.applying(transform)
            
            var position = layer.position
            
            position.x -= oldPoint.x
            position.x += newPoint.x
            
            position.y -= oldPoint.y
            position.y += newPoint.y
            
            layer.position = position
            layer.anchorPoint = point
        }
    }
}
