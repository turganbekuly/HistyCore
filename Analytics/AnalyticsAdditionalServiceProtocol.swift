//
//  AnalyticsAdditionalServiceProtocol.swift
//  Muna
//
//  Created by Акарыс Турганбекулы on 15.05.2024.
//

import Foundation

public protocol AnalyticsAdditionalServiceProtocol {
    func setup(id: String)
    func logEvent(name: String, properties: [String: Any]?)
    func logEventOnce(name: String, properties: [String: Any]?)
    func setOnce(name: String, value: NSObject)
    func setPersonProperty(name: String, value: NSObject)
    func addPersonProperty(name: String, by value: Int)
}
