//
//  Analytics+NonStandartEvents.swift
//  Muna
//
//  Created by Акарыс Турганбекулы on 15.05.2024.
//

import Foundation

enum AnalyticsPurhcaseState: String {
    case started
    case finished
    case failed
    case cancelled
}

extension AnalyticsServiceProtocol {
    func logShowWindow(name: String) {
        self.logEvent(name: "Show Window", properties: [
            "type": name,
        ])
    }

    func logTipGiven(isSubscription: Bool) {
        self.logEvent(name: "Gave Tip", properties: [
            "type": isSubscription ? "subscription" : "one_time_purchase",
        ])

        self.setPersonProperty(
            name: "supporter",
            value: true
        )
    }

    func logPurchaseState(
        state: AnalyticsPurhcaseState,
        isSubscription: Bool,
        message: String? = nil
    ) {
        if let message = message {
            self.logEvent(name: "Purchase State", properties: [
                "state": state.rawValue,
                "type": isSubscription ? "subscription" : "one_time_purchase",
                "message": message
            ])
        } else {
            self.logEvent(name: "Purchase State", properties: [
                "state": state.rawValue,
                "type": isSubscription ? "subscription" : "one_time_purchase",
            ])
        }
    }
}
