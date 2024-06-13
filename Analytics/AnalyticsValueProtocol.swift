//
//  AnalyticsValueProtocol.swift
//  Muna
//
//  Created by Акарыс Турганбекулы on 15.05.2024.
//

import Foundation

public protocol AnalyticsValueProtocol {
    analyticsValue: NSObject { get }
}

public extension String: AnalyticsValueProtocol {
    public var analyticsValue: NSObject {
        return self as NSObject
    }
}

public extension Int: AnalyticsValueProtocol {
    public var analyticsValue: NSObject {
        return self as NSObject
    }
}

public extension Bool: AnalyticsValueProtocol {
    public var analyticsValue: NSObject {
        return self as NSObject
    }
}

public extension CGFloat: AnalyticsValueProtocol {
    public var analyticsValue: NSObject {
        return self as NSObject
    }
}

public extension Float: AnalyticsValueProtocol {
    public var analyticsValue: NSObject {
        return self as NSObject
    }
}

public extension Double: AnalyticsValueProtocol {
    public var analyticsValue: NSObject {
        return self as NSObject
    }
}

public extension AnalyticsPropertyNameProtocol {
    var analyticsValue: NSObject {
        return self.propertiesEventName as NSObject
    }
}
