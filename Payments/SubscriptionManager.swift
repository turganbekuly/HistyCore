//
//  SubscriptionManager.swift
//  PastePort
//
//  Created by Акарыс Турганбекулы on 11.04.2024.
//

import Foundation
import SwiftyStoreKit

public final class SubscriptionManager {
    public enum CurrentValidationState {
        case purchased
        case notPurchased
        case expired
        case noProductToValidate
        case error(Error)
    }

    public enum CurrentPurchaseState {
        case purchased
        case cancelled
        case notPurchased
        case error(Error)
    }
    
    public enum CurrentProductRequestState {
        case requested
        case error(Error)
    }

    public typealias PurchaseCompletionBlock = (CurrentPurchaseState) -> Void
    public typealias ValidationCompletionBlock = (CurrentValidationState) -> Void

    private(set) var monthlyProductItem = SubscriptionProductItem(id: ProductIds.monthlySubscription, productType: .subscription)
    private(set) var yearlyProductItem = SubscriptionProductItem(id: ProductIds.yearlySubscription, productType: .subscription)
    private(set) var lifetimeProductItem = SubscriptionProductItem(id: ProductIds.lifetimeSubscription, productType: .oneTime)

    public var products: [String: SubscriptionProductItem] {
        return [
            ProductIds.monthlySubscription.rawValue: self.monthlyProductItem,
            ProductIds.yearlySubscription.rawValue: self.yearlyProductItem,
            ProductIds.lifetimeSubscription.rawValue: self.lifetimeProductItem
        ]
    }

    private let subscriptionProductsService: SubscriptionProductsService
    private let subscriptionPurchaseService: SubscriptionProductPurchaseService
    private let subscriptionRecieptValidationService: SubscriptionRecieptValidationService

    private var loadingProductsTry = 0

    public init(
        subscriptionProductsService: SubscriptionProductsService,
        subscriptionPurchaseService: SubscriptionProductPurchaseService,
        subscriptionRecieptValidationService: SubscriptionRecieptValidationService
    ) {
        self.subscriptionProductsService = subscriptionProductsService
        self.subscriptionPurchaseService = subscriptionPurchaseService
        self.subscriptionRecieptValidationService = subscriptionRecieptValidationService

        self.subscriptionPurchaseService.checkTransactions = { [weak self] purchases in
            guard !purchases.isEmpty else { return }
            self?.validateSubscription(nil)
        }
    }

    public func completeTransaction() {
        self.subscriptionPurchaseService.completeTransactions()
    }

    public func loadProducts(_ completion: ((CurrentProductRequestState) -> Void)? = nil) {
        self.subscriptionProductsService.requestProducts(forIds: [.monthlySubscription, .yearlySubscription, .lifetimeSubscription]) {
            switch $0 {
            case let .requested(products):
                self.monthlyProductItem.product = products.first(where: { $0.productIdentifier ==  ProductIds.monthlySubscription.rawValue })
                self.yearlyProductItem.product = products.first(where: { $0.productIdentifier ==  ProductIds.yearlySubscription.rawValue })
                self.lifetimeProductItem.product = products.first(where: { $0.productIdentifier == ProductIds.lifetimeSubscription.rawValue })
                completion?(.requested)
            case let .failed(error):
                completion?(.error(error))
                appAssertionFailure("Error on loading products: \(error)")
            case .none:
                completion?(.error(PasteportError.uknownError))
            case .requesting:
                break
            }
        }
    }

    public func buyProduct(_ productId: ProductIds, completion: @escaping PurchaseCompletionBlock) {
        guard let inAppItem = self.products[productId.rawValue], let product = inAppItem.product else {
            self.loadingProductsTry += 1
            if loadingProductsTry < 3 {
                self.loadProducts { [weak self] result in
                    switch result {
                    case .requested:
                        self?.buyProduct(productId, completion: completion)
                    case .error:
                        OperationQueue.main.addOperation {
                            completion(.error(PasteportError.cantGetInAppProducts))
                        }
                    }
                }
            } else {
                self.loadingProductsTry = 0
                OperationQueue.main.addOperation {
                    completion(.error(PasteportError.cantGetInAppProducts))
                }
            }
            return
        }
        self.loadingProductsTry = 0

        self.subscriptionPurchaseService.buyProduct(product) { [weak self] result in
            switch result {
            case let .success(purchaseDetails):
                switch inAppItem.productType {
                case .oneTime:
                    ServiceLocator.shared.securityStorage.save(
                        double: purchaseDetails.originalPurchaseDate.timeIntervalSince1970,
                        for: SecurityStorage.Key.purchaseTipDate.rawValue
                    )
                    completion(.purchased)
                case .subscription:
                    ServiceLocator.shared.securityStorage.save(
                        string: product.productIdentifier,
                        forKey: SecurityStorage.Key.productIdSubscription.rawValue
                    )
                    self?.validateSubscription { result in
                        switch result {
                        case .purchased, .noProductToValidate:
                            completion(.purchased)
                        case let .error(error):
                            completion(.error(error))
                        case .notPurchased:
                            completion(.notPurchased)
                        case .expired:
                            completion(.error(PasteportError.uknownError))
                        }
                    }
                }
            case let .failure(error):
                switch error.code {
                case .paymentCancelled:
                    completion(.cancelled)
                default:
                    completion(.error(error))
                    appAssertionFailure("Error: \(error) on purchasing product: \(productId.rawValue)")
                }
            }
        }
    }

    public func restorePurchases(completion: ValidationCompletionBlock?) {
        self.subscriptionPurchaseService.restorePurchases { [weak self] purchases in
            guard let self = self else { return }
            guard let purchase = purchases.last(where: { $0.productId == self.monthlyProductItem.id.rawValue }) else {
                completion?(.noProductToValidate)
                return
            }
            ServiceLocator.shared.securityStorage.save(string: purchase.productId, forKey: SecurityStorage.Key.productIdSubscription.rawValue)
            self.validateSubscription { result in
                completion?(result)
            }
        }
    }

    public func validateSubscription(_ completion: ValidationCompletionBlock?) {
        guard let productId = ServiceLocator.shared.securityStorage.getString(
                forKey: SecurityStorage.Key.productIdSubscription.rawValue
        ) else {
            ServiceLocator.shared.securityStorage.save(
                bool: false,
                forKey: SecurityStorage.Key.isUserPro.rawValue
            )
            NotificationCenter.default.post(name: .isProUpdated, object: nil)
            completion?(.noProductToValidate)
            return
        }

        guard let product = self.products[productId], product.id != .lifetimeSubscription else {
            appAssertionFailure("No product for product id: \(productId)")
            completion?(.error(PasteportError.wrongProductForValidation))
            return
        }

        self.subscriptionRecieptValidationService.validateSubscription(forProduct: product) { result in
            switch result {
            case let .success(successResult):
                switch successResult {
                case let .expired(expiryDate, _):
                    ServiceLocator.shared.securityStorage.save(
                        bool: false,
                        forKey: SecurityStorage.Key.isUserPro.rawValue
                    )
                    ServiceLocator.shared.securityStorage.remove(
                        forKey: SecurityStorage.Key.productIdSubscription.rawValue
                    )
                    ServiceLocator.shared.securityStorage.save(
                        double: expiryDate.timeIntervalSince1970,
                        for: SecurityStorage.Key.expiredDate.rawValue
                    )
                    NotificationCenter.default.post(name: .isProUpdated, object: nil)
                    completion?(.expired)
                case .notPurchased:
                    ServiceLocator.shared.securityStorage.save(
                        bool: false,
                        forKey: SecurityStorage.Key.isUserPro.rawValue
                    )
                    ServiceLocator.shared.securityStorage.remove(
                        forKey: SecurityStorage.Key.productIdSubscription.rawValue
                    )
                    NotificationCenter.default.post(name: .isProUpdated, object: nil)
                    completion?(.notPurchased)
                case let .purchased(_, items):
                    ServiceLocator.shared.securityStorage.save(
                        bool: true,
                        forKey: SecurityStorage.Key.isUserPro.rawValue
                    )
                    guard let item = items.first(where: { item in
                        guard let expirationDate = item.subscriptionExpirationDate else {
                            return false
                        }

                        return expirationDate.timeIntervalSince1970 > Date().timeIntervalSince1970
                    }) else {
                        completion?(.purchased)
                        return
                    }
                    ServiceLocator.shared.securityStorage.save(
                        string: item.productId,
                        forKey: SecurityStorage.Key.productIdSubscription.rawValue
                    )
                    ServiceLocator.shared.securityStorage.save(
                        double: item.subscriptionExpirationDate?.timeIntervalSince1970,
                        for: SecurityStorage.Key.expirationDate.rawValue
                    )
                    NotificationCenter.default.post(name: .isProUpdated, object: nil)
                    completion?(.purchased)
                }
            case let .failure(error):
                appAssertionFailure("Error on subscription validation: \(error)")
                completion?(.error(error))
            case .noProductToValidate:
                completion?(.noProductToValidate)
            }
        }
    }

    public func isNeededToShowSubscriptions() -> Bool {
        let isUserPro = ServiceLocator.shared.securityStorage.getBool(forKey: SecurityStorage.Key.isUserPro.rawValue) ?? false
        
        guard !isUserPro else {
            return false
        }

        let expiredDate = ServiceLocator.shared.securityStorage.getDouble(forKey: SecurityStorage.Key.expiredDate.rawValue)
        let lifeimeTipDate = ServiceLocator.shared.securityStorage.getDouble(forKey: SecurityStorage.Key.purchaseTipDate.rawValue)

        let oneMonthInSeconds = PresentationLayerConstants.oneMonthInSeconds
        let oneYearInSeconds = PresentationLayerConstants.oneYearInSeconds
        
        let isExpirationValidForShowing: Bool
        let isTipsPayDateValidForShowing: Bool
        
        if let expiredDate = expiredDate {
            let dateSinceExpiration = Date().timeIntervalSince1970 - expiredDate
            if dateSinceExpiration > oneMonthInSeconds {
                isExpirationValidForShowing = true
            } else if dateSinceExpiration > oneYearInSeconds {
                isExpirationValidForShowing = true
            } else {
                isExpirationValidForShowing = false
            }
        } else {
            isExpirationValidForShowing = true
        }

        if let oneTimeTipDate = lifeimeTipDate {
            let dateSinceTip = Date().timeIntervalSince1970 - oneTimeTipDate
            if dateSinceTip > oneMonthInSeconds * 4 {
                isTipsPayDateValidForShowing = true
            } else {
                isTipsPayDateValidForShowing = false
            }
        } else {
            isTipsPayDateValidForShowing = true
        }

        return isExpirationValidForShowing && isTipsPayDateValidForShowing
    }
}

public extension Notification.Name {
    static let isProUpdated = Notification.Name("isProUpdated")
}
