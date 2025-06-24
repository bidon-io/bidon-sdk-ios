//
//  ViewHelper.swift
//  Bidon
//
//  Created by Bidon Team on 26.04.2023.
//

import Foundation
import UIKit


struct Viewability {
    var view: UIView
    var minVisiblePercentage: CGFloat = 0.8

    func isVisible() -> Bool {
        return ![
            !view.isHidden,
            !hasHiddenSuperview(),
            isIntersectsParentWindow(),
            isIntersectsSuperview(),
            isExistsInTopViewControllerHierarchy(),
            !isHiddenByAnotherView(),
            !isHiddenByAnotherWindow()
        ].contains(false)
    }
}


private extension Viewability {
    func hasHiddenSuperview() -> Bool {
        var targetView = view
        while let superview = targetView.superview {
            guard !superview.isHidden else { return true }
            targetView = superview
        }
        return false
    }

    func parentWindow() -> UIWindow? {
        var targetView = view
        while let superview = targetView.superview {
            if let window = superview as? UIWindow {
                return window
            }
            targetView = superview
        }
        return nil
    }

    func isIntersectsParentWindow() -> Bool {
        guard
            let window = parentWindow(),
            let superview = view.superview
        else { return false }

        let viewableRect = window.frame.intersection(window.screen.bounds)
        let windowArea = window.frame.width * window.frame.height
        let viewableArea = viewableRect.width * viewableRect.height
        let frameToParentWindow = superview.convert(view.frame, to: window)

        let isWindowViewable = viewableArea >= (windowArea * minVisiblePercentage)
        let isIntersectsWindowBounds = frameToParentWindow.intersects(window.bounds)

        return isWindowViewable && isIntersectsWindowBounds
    }

    func isIntersectsSuperview() -> Bool {
        guard let superview = view.superview else { return false }

        let intersection = view.frame.intersection(superview.bounds)
        let intersectionArea = intersection.width * intersection.height
        let viewArea = view.frame.width * view.frame.height

        return intersectionArea >= (viewArea * minVisiblePercentage)
    }

    func isExistsInTopViewControllerHierarchy() -> Bool {
        guard let controller = UIApplication.shared.bd.topViewcontroller else { return false }
        let isSameWindows = Viewability(view: controller.view).parentWindow() == parentWindow()
        return !isSameWindows || isExistsInHierarchy(of: controller.view)
    }

    func isExistsInHierarchy(of view: UIView) -> Bool {
        guard self.view != view else { return true }
        guard !view.subviews.isEmpty else { return false }

        return view.subviews.reduce(false) { $0 || isExistsInHierarchy(of: $1) }
    }

    func isHiddenByAnotherView() -> Bool {
        guard let window = UIApplication.shared.bd.window else { return true }

        let frameToKeyWindow = view.convert(view.frame, to: window)
        let originalArea = frameToKeyWindow.width * frameToKeyWindow.height
        let subviews = allViewsHigherOnScreen(of: view)

        return subviews.contains { subview in
            let subviewFrameToKeyWindow = subview.convert(subview.frame, to: window)
            let hiddenRect = frameToKeyWindow.intersection(subviewFrameToKeyWindow)
            let hiddenArea = hiddenRect.width * hiddenRect.height
            let visiblePercent = (originalArea - hiddenArea) / originalArea
            return visiblePercent < minVisiblePercentage
        }
    }

    func isHiddenByAnotherWindow() -> Bool {
        guard let window = UIApplication.shared.bd.window else { return true }

        let frameToKeyWindow = view.convert(view.frame, to: window)
        let originalArea = frameToKeyWindow.width * frameToKeyWindow.height
        let windows = UIApplication.shared.bd.windows

        return windows
            .filter { $0.isOpaque && $0.windowLevel > window.windowLevel }
            .contains { subwindow in
                let subwindowFrame = subwindow.convert(subwindow.bounds, to: subwindow)
                let hiddenRect = frameToKeyWindow.intersection(subwindowFrame)
                let hiddenArea = hiddenRect.width * hiddenRect.height
                let visiblePercent = (originalArea - hiddenArea) / originalArea
                return visiblePercent < minVisiblePercentage
            }
    }

    func allViewsHigherOnScreen(of view: UIView) -> [UIView] {
        guard
            let superview = view.superview,
            let currentIndex = superview.subviews.firstIndex(of: view)
        else { return [] }

        return superview
            .subviews
            .enumerated()
            .filter { $0.offset > currentIndex }
            .map { $0.element }
            .reduce([]) { $0 + allViewsHigherOnScreen(of: $1) }
    }
}
