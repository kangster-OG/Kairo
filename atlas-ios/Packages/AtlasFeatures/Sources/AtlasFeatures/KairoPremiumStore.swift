import AtlasDomain
import Foundation
import StoreKit

enum KairoPremiumStore {
    static let annualProductID = "com.dkang2000.Atlas.kairo.pro.annual"
    static let monthlyProductID = "com.dkang2000.Atlas.kairo.pro.monthly"
    static let annualLastChanceProductID = "com.dkang2000.Atlas.kairo.pro.annual.lastchance"

    static func productID(for plan: AtlasOnboardingPremiumPlan) -> String {
        switch plan {
        case .annual:
            return annualProductID
        case .monthly:
            return monthlyProductID
        case .annualLastChance:
            return annualLastChanceProductID
        }
    }

    static func purchase(plan: AtlasOnboardingPremiumPlan) async throws -> Bool {
        let productID = productID(for: plan)
        let products = try await Product.products(for: [productID])
        guard let product = products.first else {
            throw KairoPremiumStoreError.productNotFound(productID)
        }
        if plan.requiresSevenDayTrial {
            try validateSevenDayTrial(product)
        }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    static func restorePurchasedPlan() async throws -> AtlasOnboardingPremiumPlan {
        try await AppStore.sync()

        for await result in Transaction.currentEntitlements {
            let transaction = try checkVerified(result)
            guard transaction.revocationDate == nil,
                  let plan = plan(for: transaction.productID)
            else {
                continue
            }
            return plan
        }

        throw KairoPremiumStoreError.noActiveSubscription
    }

    private static func plan(for productID: String) -> AtlasOnboardingPremiumPlan? {
        switch productID {
        case annualProductID:
            return .annual
        case monthlyProductID:
            return .monthly
        case annualLastChanceProductID:
            return .annualLastChance
        default:
            return nil
        }
    }

    private static func validateSevenDayTrial(_ product: Product) throws {
        guard let offer = product.subscription?.introductoryOffer else {
            throw KairoPremiumStoreError.missingSevenDayTrial(product.id)
        }
        let isSevenDays = (offer.period.unit == .day && offer.period.value == 7)
            || (offer.period.unit == .week && offer.period.value == 1)
        guard isSevenDays else {
            throw KairoPremiumStoreError.missingSevenDayTrial(product.id)
        }
    }

    private static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw KairoPremiumStoreError.unverifiedTransaction
        }
    }
}

private extension AtlasOnboardingPremiumPlan {
    var requiresSevenDayTrial: Bool {
        switch self {
        case .annual, .monthly:
            return true
        case .annualLastChance:
            return false
        }
    }
}

enum KairoPremiumStoreError: LocalizedError {
    case productNotFound(String)
    case missingSevenDayTrial(String)
    case unverifiedTransaction
    case noActiveSubscription

    var errorDescription: String? {
        switch self {
        case .productNotFound(let productID):
            return "Kairo Pro product '\(productID)' was not found. Confirm this product ID exists in App Store Connect and is available for this build."
        case .missingSevenDayTrial(let productID):
            return "Kairo Pro product '\(productID)' does not expose a 7-day introductory trial. Configure the 7-day free trial in App Store Connect before launch."
        case .unverifiedTransaction:
            return "The App Store transaction could not be verified."
        case .noActiveSubscription:
            return "No active Kairo Pro subscription was found for this Apple ID."
        }
    }
}
