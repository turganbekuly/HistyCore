//
//  SubscriptionProductsService.swift
//  PastePort
//
//  Created by Акарыс Турганбекулы on 11.04.2024.
//

import StoreKit

public final class SubscriptionProductsService: NSObject {
    public enum Status {
        case none
        case requesting(SKProductsRequest)
        case requested([SKProduct])
        case failed(Error)
    }
    
    // MARK: - Properties
    
    private(set) var status: Status = .none {
        didSet {
            onStatusChanged?(status)
        }
    }
    
    public var onStatusChanged: ((Status) -> Void)?
    
    public var skRequest: SKProductsRequest!
    
    public func requestProducts(forIds ids: [ProductIds], _ onCompletion: ((Status) -> Void)?) {
        self.onStatusChanged = onCompletion
        switch self.status {
        case .requesting:
            return
        default:
            break
        }

        self.skRequest = SKProductsRequest(productIdentifiers: Set(ids.map { $0.rawValue }))
        self.skRequest.delegate = self

        self.status = .requesting(skRequest)

        self.skRequest.start()
    }
}

public extension SubscriptionProductsService: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.status = .requested(response.products)
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        self.status = .failed(error)
    }
}
