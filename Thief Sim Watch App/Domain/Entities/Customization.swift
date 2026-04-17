import Foundation
import SwiftUI

/// Possible gameplay modifiers provided by skins.
enum SkinModifier: String, Codable {
    case none
    case silentSafeCracking // Ninja: 15% slower detection
    case preciseHacking // Neon: +20% hack tolerance
}

/// A visual skin for the character with gameplay modifiers.
struct Skin: Identifiable, Equatable {
    let id: SkinID
    let name: String
    let color: Color
    let price: Int
    let description: String
    let modifier: SkinModifier
    let modifierDescription: String
}

/// A cosmetic accessory for the character.
struct Accessory: Identifiable, Equatable {
    let id: AccessoryID
    let name: String
    let icon: String
    let price: Int
    let offset: CGPoint
}
