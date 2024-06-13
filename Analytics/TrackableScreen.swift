//
//  TrackableScreen.swift
//  Muna
//
//  Created by Акарыс Турганбекулы on 15.05.2024.
//

import Foundation

public protocol AnalyticsPropertyNameProtocol: AnalyticsValueProtocol {
    public var propertiesEventName: String { get }
}

public extension AnalyticsPropertyNameProtocol where Self: RawRepresentable, Self.RawValue == String {
    // videoPost -> video_post
    public var propertiesEventName: String {
        var string = ""
        for character in self.rawValue {
            if character.isUppercase {
                string += "_\(character.lowercased())"
            } else {
                string += "\(character)"
            }
        }
        return string
    }
}

public enum TrackableScreen: String, AnalyticsPropertyNameProtocol {
    case itemsList
    case settings
    case textTaskCreation
    case screenshotTaskCreation

    // videoPost -> Video Post Showed
    public var showEventName: String {
        let words = self.propertiesEventName.components(separatedBy: "_")
        let name = words.map { $0.capitalized }.joined(separator: " ")

        return "\(name) Showed"
    }

    public var valueWithFirstLetterCapital: String {
        let initialValue = self.rawValue
        var finalValue = self.rawValue
        if let firstChar = initialValue.first {
            let firstLetter = String(firstChar).capitalized
            finalValue = firstLetter + initialValue.dropFirst()
        }
        return finalValue
    }
}
