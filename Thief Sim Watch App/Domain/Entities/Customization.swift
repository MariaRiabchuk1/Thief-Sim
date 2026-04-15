import Foundation
import SwiftUI

/// A visual skin for the character.
struct Skin: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let color: Color
    let price: Int
    let description: String
}

/// A cosmetic accessory for the character.
struct Accessory: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let icon: String
    let price: Int
    let offset: CGPoint
}
