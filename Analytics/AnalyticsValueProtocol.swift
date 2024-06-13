//
//  AnalyticsValueProtocol.swift
//  Muna
//
//  Created by Акарыс Турганбекулы on 15.05.2024.
//

import Foundation

public protocol AnalyticsValueProtocol {
    var analyticsValue: NSObject { get }
}

extension String: AnalyticsValueProtocol {
    public var analyticsValue: NSObject {
        return self as NSObject
    }
}

extension Int: AnalyticsValueProtocol {
    public var analyticsValue: NSObject {
        return self as NSObject
    }
}

extension Bool: AnalyticsValueProtocol {
    public var analyticsValue: NSObject {
        return self as NSObject
    }
}

extension CGFloat: AnalyticsValueProtocol {
    public var analyticsValue: NSObject {
        return self as NSObject
    }
}

extension Float: AnalyticsValueProtocol {
    public var analyticsValue: NSObject {
        return self as NSObject
    }
}

extension Double: AnalyticsValueProtocol {
    public var analyticsValue: NSObject {
        return self as NSObject
    }
}

extension AnalyticsPropertyNameProtocol {
    var analyticsValue: NSObject {
        return self.propertiesEventName as NSObject
    }
}
