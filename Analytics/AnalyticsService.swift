//
//  AnalyticsService.swift
//  Muna
//
//  Created by Акарыс Турганбекулы on 15.05.2024.
//

import Amplitude
import Foundation

public class AnalyticsService: AnalyticsServiceProtocol {
    private let storage: StorageServiceProtocol
    private var apmplitudeId: String?
    private var additionalServices: [AnalyticsAdditionalServiceProtocol]

    private let logger: DebugLogAnalyticsProtocol = DebugXcodeLogAnalytics()

    public init(
        storage: StorageServiceProtocol,
        apmplitudeId: String?,
        additionalServices: [AnalyticsAdditionalServiceProtocol]
    ) {
        self.storage = storage
        self.apmplitudeId = apmplitudeId
        self.additionalServices = additionalServices

        if let id = apmplitudeId {
            Amplitude.instance().initializeApiKey(id)
            Amplitude.instance().trackingSessionEvents = true
            Amplitude.instance().setUserId(self.userId, startNewSession: true)
            #if DEBUG
                Amplitude.instance().optOut = true
            #else
                Amplitude.instance().optOut = false
            #endif
        }

        self.additionalServices.forEach { $0.setup(id: self.userId) }
    }

    public var userId: String {
        var id: String
        if let cachedId = self.storage.getString(forKey: "generated-auth0-user-id") {
            id = cachedId
        } else {
            let newId = UUID().uuidString
            self.storage.save(string: newId, forKey: "generated-auth0-user-id")
            id = newId
        }
        return id
    }

    public func logLaunchEvents() {
        let pair = self.buildCohortPair()

        ServiceLocator.shared.analytics.setPersonPropertyOnce(
            name: "cohort_day",
            value: pair.cohortDay
        )
        ServiceLocator.shared.analytics.setPersonPropertyOnce(
            name: "cohort_week",
            value: pair.cohortWeek
        )
        ServiceLocator.shared.analytics.setPersonPropertyOnce(
            name: "cohort_month",
            value: pair.cohortMonth
        )
        ServiceLocator.shared.analytics.setPersonPropertyOnce(
            name: "device_id",
            value: self.deviceId ?? ""
        )

        if let dictionary = Bundle.main.infoDictionary,
            let build = dictionary["CFBundleVersion"] as? String
        {
            ServiceLocator.shared.analytics.setPersonProperty(name: "build", value: build)
        }

        ServiceLocator.shared.analytics.logEventOnce(name: "App Launched First Time")
        ServiceLocator.shared.analytics.logEvent(name: "App Launched")
    }

    public var deviceId: String? {
        return Amplitude.instance().getDeviceId()
    }

    public func buildCohortPair() -> AnalyticsServiceProtocol.CohortPair {
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: Date())
        let month = calendar.component(.month, from: Date())
        let day = calendar.ordinality(of: .day, in: .year, for: Date())
        return (day ?? 0, weekOfYear, month)
    }

    public func logEvent(name: String, properties: [String: AnalyticsValueProtocol]? = nil) {
        let propertiesObjects = properties?.mapValues { $0.analyticsValue }

        if let propertiesObjects = propertiesObjects {
            Amplitude.instance().logEvent(name, withEventProperties: propertiesObjects)
        } else {
            Amplitude.instance().logEvent(name)
        }
        self.additionalServices.forEach { $0.logEvent(name: name, properties: propertiesObjects) }

        #if DEBUG
            self.logger.logEvent(name: name, properties: properties)
        #endif
    }

    public func logEventOnce(name: String, properties: [String: AnalyticsValueProtocol]? = nil) {
        let udKey = self.storageEventKey(with: name)
        if self.storage.getBool(forKey: udKey) == true {
            return
        }

        self.logEvent(name: name, properties: properties)
        self.storage.save(bool: true, forKey: udKey)
    }

    public func setPersonProperty(name: String, value: AnalyticsValueProtocol) {
        let object = value.analyticsValue

        if let identify = AMPIdentify().set(name, value: object) {
            Amplitude.instance().identify(identify)
        }
        self.additionalServices.forEach { $0.setPersonProperty(name: name, value: object) }

        #if DEBUG
            self.logger.setUserProperty(name: name, value: value)
        #endif
    }

    public func setPersonPropertyOnce(name: String, value: AnalyticsValueProtocol) {
        let object = value.analyticsValue

        if let identify = AMPIdentify().setOnce(name, value: object) {
            Amplitude.instance().identify(identify)
        }

        let udKey = self.storageUserPropertiesKey(with: name)
        if self.storage.getBool(forKey: udKey) == nil {
            // ONEDAY: - Rething logic if completion would be false
            self.additionalServices.forEach { $0.setPersonProperty(name: name, value: object) }
            self.storage.save(bool: true, forKey: udKey)

            let udValueKey = self.storageUserPropertiesValueKey(with: name)
            self.storage.save(object: object, for: udValueKey)

            #if DEBUG
                self.logger.setUserPropertyOnce(name: name, value: value)
            #endif
        }
    }

    public func increasePersonProperty(name: String, by value: Int) {
        if let identify = AMPIdentify().add(name, value: value as NSObject) {
            Amplitude.instance().identify(identify)
        }

        let udKey = self.storageUserPropertiesKey(with: name)
        let storedValue = self.storage.getInt(forKey: udKey)
        var newValue: Int = storedValue ?? 0
        newValue += value
        self.storage.save(int: newValue, forKey: udKey)
        self.additionalServices.forEach { $0.setPersonProperty(name: name, value: "\(value)" as NSObject) }

        #if DEBUG
            self.logger.increaseUserProperty(name: name, by: value)
        #endif
    }

    // MARK: - Helpers

    private func storageUserPropertiesKey(with name: String) -> String {
        return "_analytics-reports.up.\(name)"
    }

    private func storageUserPropertiesValueKey(with name: String) -> String {
        return "_analytics-reports.up.value.\(name)"
    }

    private func storageEventKey(with name: String) -> String {
        return "_analytics-reports.event.\(name)"
    }
}
