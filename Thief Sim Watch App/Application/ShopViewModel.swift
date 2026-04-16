import Foundation
import Combine

/// Drives the shop screen.
///
/// Reads catalogs and ownership from `GameSession`, routes purchases back
/// to it, and owns the info-alert presentation state for upgrade details.
final class ShopViewModel: ObservableObject {
    let session: GameSession

    @Published var infoAlert: Upgrade? = nil

    var onClose: (() -> Void)?

    init(session: GameSession) {
        self.session = session
    }

    func close() {
        onClose?()
    }

    func showInfo(_ item: Upgrade) {
        infoAlert = item
    }

    func buyUpgrade(_ item: Upgrade) {
        session.buyUpgrade(item)
    }

    func buySkin(_ skin: Skin) {
        session.buySkin(skin)
    }

    func buyAccessory(_ accessory: Accessory) {
        session.buyAccessory(accessory)
    }

    func equipAccessory(_ accessory: Accessory) {
        session.currentAccessoryName = accessory.name
    }
}
