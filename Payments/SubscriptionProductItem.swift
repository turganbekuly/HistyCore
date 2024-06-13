//
//  SubscriptionProductItem.swift
//  PastePort
//
//  Created by Акарыс Турганбекулы on 11.04.2024.
//

import StoreKit

public struct SubscriptionProductItem {
    public enum ProductType {
        case oneTime
        case subscription
    }
    
    // MARK: - Properties
    
    public var id: ProductIds
    
    public var product: SKProduct?
    
    public var productType: ProductType
    
    // MARK: - Init
    
    public init(id: ProductIds, productType: ProductType) {
        self.id = id
        self.productType = productType
    }
    
    // MARK: - Methods
    
    public mutating func addProduct(_ product: SKProduct?) {
        self.product = product
    }
}
