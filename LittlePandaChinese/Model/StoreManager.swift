import Combine
import Foundation
import StoreKit

/// Local StoreKit 2 stub. The non-consumable is declared in Products.storekit for
/// simulator testing. This prototype does not create the product in App Store Connect.
enum ProductID {
    static let unlockAll = "com.limuye.littlepandachinese.unlockall"
}

@MainActor
final class StoreManager: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isUnlockedAll = false
    @Published private(set) var purchasing = false
    @Published var lastError: String?

    private var updates: Task<Void, Never>?
    private var started = false

    /// StoreKit stays quiet until a grown-up opens settings, so episode playback
    /// and unit tests never wait on the App Store.
    func start() {
        guard !started else { return }
        started = true
        updates = Task { [weak self] in
            for await update in Transaction.updates {
                guard case .verified(let transaction) = update else { continue }
                await self?.handle(transaction)
                await transaction.finish()
            }
        }
        Task { await load(); await refresh() }
    }

    var unlockProduct: Product? { products.first { $0.id == ProductID.unlockAll } }

    func load() async {
        do {
            products = try await Product.products(for: [ProductID.unlockAll])
        } catch {
            lastError = error.localizedDescription
        }
    }

    func refresh() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == ProductID.unlockAll, transaction.revocationDate == nil {
                unlocked = true
            }
        }
        isUnlockedAll = unlocked
    }

    func buy(_ product: Product) async {
        purchasing = true
        defer { purchasing = false }
        do {
            switch try await product.purchase() {
            case .success(let result):
                guard case .verified(let transaction) = result else {
                    lastError = "The App Store could not verify that purchase."
                    return
                }
                await handle(transaction)
                await transaction.finish()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
        } catch {
            lastError = error.localizedDescription
        }
        await refresh()
    }

    private func handle(_ transaction: Transaction) async {
        guard transaction.productID == ProductID.unlockAll else { return }
        isUnlockedAll = transaction.revocationDate == nil
    }
}
