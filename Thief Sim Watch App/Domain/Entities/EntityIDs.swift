import Foundation

/// Stable, typed identifiers for every catalog entity.
///
/// Using enums means two items with the same display name (or a typo in
/// one) can't collide — the compiler enforces uniqueness, and `Identifiable`
/// gets a reliable key without relying on a runtime-generated UUID.
enum DistrictID: String, Codable, CaseIterable, Hashable {
    case outskirts
    case center
    case island
}

enum UpgradeID: String, Codable, CaseIterable, Hashable {
    case stethoscope
    case lockpicks
    case smokeBomb
    case emp
}

enum SkinID: String, Codable, CaseIterable, Hashable {
    case classic
    case ninja
    case neon
}

enum AccessoryID: String, Codable, CaseIterable, Hashable {
    case cap
    case tophat
    case backpack
    case glasses
}
