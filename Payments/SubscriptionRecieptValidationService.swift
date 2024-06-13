//
//  InAppRecieptValidationService.swift
//  PastePort
//
//  Created by Акарыс Турганбекулы on 11.04.2024.
//

import SwiftyStoreKit

public final class SubscriptionRecieptValidationService {
    public enum State {
        case noProductToValidate
        case success(VerifySubscriptionResult)
        case failure(ReceiptError)
    }

    public func validateSubscription(forProduct product: SubscriptionProductItem, _ completion: @escaping (State) -> Void) {
        let recieptValidator: AppleReceiptValidator

        #if DEBUG
        recieptValidator = AppleReceiptValidator(service: .sandbox, sharedSecret: "bea3091157dd416faffd267ba79fe77d")
        #else
        recieptValidator = AppleReceiptValidator(service: .production, sharedSecret: "bea3091157dd416faffd267ba79fe77d")
        #endif
        
        SwiftyStoreKit.verifyReceipt(using: recieptValidator) { result in
            switch result {
            case let .success(receipt):
                guard product.id == .monthlySubscription || product.id == .yearlySubscription else {
                    completion(.noProductToValidate)
                    return
                }
                let purchaseResult = SwiftyStoreKit.verifySubscription(
                    ofType: .autoRenewable, // or .nonRenewing (see below)
                    productId: product.id.rawValue,
                    inReceipt: receipt
                )
                completion(.success(purchaseResult))
            case let .error(error):
                completion(.failure(error))
            }
        }
    }
}

