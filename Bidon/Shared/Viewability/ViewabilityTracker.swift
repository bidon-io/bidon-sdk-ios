//
//  ViewabilityTracker.swift
//  Bidon
//
//  Created by Bidon Team on 26.04.2023.
//

import Foundation
import UIKit


protocol ViewabilityTracker {
    func startTracking(
        view: UIView,
        impression: @escaping () -> ()
    )

    func finishTracking()
}


extension Viewability {
    final class Tracker: ViewabilityTracker {
        private weak var view: UIView?
        private var timer: Timer?
        private let interval: TimeInterval = 0.25
        private let minImpressionDuration = 1.0
        private var viewableInterval: TimeInterval = 0.0

        func startTracking(
            view: UIView,
            impression: @escaping () -> ()
        ) {
            guard !(timer?.isValid ?? false) else { return }

            self.view = view

            let timer = Timer(
                timeInterval: interval,
                repeats: true
            ) { [weak self] timer in
                self?.validateViewability(
                    timer: timer,
                    impression: impression
                )
            }

            RunLoop.main.add(timer, forMode: .default)
            self.timer = timer
        }

        func finishTracking() {
            timer?.invalidate()
            view = nil
        }

        private func validateViewability(
            timer: Timer,
            impression: @escaping () -> ()
        ) {
            guard let view = view else {
                timer.invalidate()
                return
            }

            guard
                UIApplication.shared.applicationState == .active,
                Viewability(view: view).isVisible()
            else {
                viewableInterval = 0
                return
            }

            viewableInterval += interval

            if viewableInterval >= minImpressionDuration {
                impression()
            }
        }
    }
}
