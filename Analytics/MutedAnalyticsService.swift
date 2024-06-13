//
//  MutedAnalyticsService.swift
//  Muna
//
//  Created by Акарыс Турганбекулы on 15.05.2024.
//

import Foundation

public struct DeferredEvent {
    public enum Event {
        case event(name: String, properties: [String: AnalyticsValueProtocol]?)
        case personProperty(name: String, value: AnalyticsValueProtocol)
        case incresePersonProperty(name: String, value: Int)
    }

    let event: Event
    let isOnce: Bool
}

public class MutedAnalyticsService: AnalyticsServiceProtocol {
    public var events: [DeferredEvent] = []
    public var shouldLogLaunchEvents: Bool = false

    public func logLaunchEvents() {
        self.shouldLogLaunchEvents = true
    }

    public func logEvent(
        name: String,
        properties: [String: AnalyticsValueProtocol]?
    ) {
        self.events.append(
            .init(event: .event(
                    name: name,
                    properties: properties
            ),
            isOnce: false)
        )
    }

    public func logEventOnce(
        name: String,
        properties: [String: AnalyticsValueProtocol]?
    ) {
        self.events.append(
            .init(event: .event(
                    name: name,
                    properties: properties
            ),
            isOnce: true)
        )
    }

    public func setPersonProperty(name: String, value: AnalyticsValueProtocol) {
        self.events.append(
            .init(event: .personProperty(
                    name: name,
                    value: value
            ),
            isOnce: false)
        )
    }

    public func setPersonPropertyOnce(name: String, value: AnalyticsValueProtocol) {
        self.events.append(
            .init(event: .personProperty(
                    name: name,
                    value: value
            ),
            isOnce: true)
        )
    }

    public func increasePersonProperty(name: String, by value: Int) {
        self.events.append(
            .init(event: .incresePersonProperty(
                    name: name,
                    value: value
            ),
            isOnce: false)
        )
    }
}
