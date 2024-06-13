//
//  AnalyticsServiceProtocol.swift
//  Muna
//
//  Created by Акарыс Турганбекулы on 15.05.2024.
//

import Foundation

public protocol AnalyticsServiceProtocol {
    typealias CohortPair = (cohortDay: Int, cohortWeek: Int, cohortMonth: Int)

    func logLaunchEvents()

    func logEvent(name: String, properties: [String: AnalyticsValueProtocol]?)
    func logEventOnce(name: String, properties: [String: AnalyticsValueProtocol]?)

    func setPersonProperty(name: String, value: AnalyticsValueProtocol)
    func setPersonPropertyOnce(name: String, value: AnalyticsValueProtocol)

    func increasePersonProperty(name: String, by value: Int)
}

extension AnalyticsServiceProtocol {
    func logEvent(name: String) {
        self.logEvent(name: name, properties: nil)
    }

    func logEventOnce(name: String) {
        self.logEventOnce(name: name, properties: nil)
    }
}
