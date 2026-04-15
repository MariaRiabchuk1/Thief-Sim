import WatchKit

/// Provides haptic feedback via the device.
protocol HapticProvider {
    func play(_ type: WKHapticType)
}

/// Native Apple Watch implementation of haptic feedback.
class WatchHapticProvider: HapticProvider {
    func play(_ type: WKHapticType) {
        WKInterfaceDevice.current().play(type)
    }
}
