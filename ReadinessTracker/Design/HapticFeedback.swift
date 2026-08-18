import SwiftUI
import UIKit

/// Centralized haptic feedback engine for the app.
/// Uses UIKit feedback generators for tactile responses on interactions.
@MainActor
enum Haptic {
    private static let lightImpactGen = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpactGen = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyImpactGen = UIImpactFeedbackGenerator(style: .heavy)
    private static let rigidImpactGen = UIImpactFeedbackGenerator(style: .rigid)
    private static let softImpactGen = UIImpactFeedbackGenerator(style: .soft)
    private static let selectionGen = UISelectionFeedbackGenerator()
    private static let notificationGen = UINotificationFeedbackGenerator()
    
    static func prepare() {
        lightImpactGen.prepare()
        mediumImpactGen.prepare()
        selectionGen.prepare()
        notificationGen.prepare()
    }
    
    /// Light tap — for subtle interactions (toggle switches, small buttons)
    static func tap() {
        lightImpactGen.impactOccurred()
    }
    
    /// Medium tap — for standard button presses, card taps
    static func press() {
        mediumImpactGen.impactOccurred()
    }
    
    /// Heavy impact — for major actions (delete, confirm, significant state change)
    static func heavyImpact() {
        heavyImpactGen.impactOccurred()
    }
    
    /// Rigid tap — crisp, precise feedback for toggles and switches
    static func rigid() {
        rigidImpactGen.impactOccurred()
    }
    
    /// Soft tap — gentle feedback for scroll snapping, subtle interactions
    static func soft() {
        softImpactGen.impactOccurred()
    }
    
    /// Selection change — for picker wheels, segmented controls, period selectors
    static func selectionChanged() {
        selectionGen.selectionChanged()
    }
    
    /// Success — for completed operations, successful sync, data saved
    static func success() {
        notificationGen.notificationOccurred(.success)
    }
    
    /// Warning — for partial failures, attention needed
    static func warning() {
        notificationGen.notificationOccurred(.warning)
    }
    
    /// Error — for failures, invalid actions
    static func error() {
        notificationGen.notificationOccurred(.error)
    }
}

// MARK: - SwiftUI View Modifiers

struct HapticTapModifier: ViewModifier {
    let style: HapticStyle
    let action: () -> Void
    
    enum HapticStyle {
        case tap, press, heavy, rigid, soft
    }
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                switch style {
                case .tap: Haptic.tap()
                case .press: Haptic.press()
                case .heavy: Haptic.heavyImpact()
                case .rigid: Haptic.rigid()
                case .soft: Haptic.soft()
                }
                action()
            }
    }
}

extension View {
    /// Adds haptic feedback on tap with the specified style
    func hapticTap(_ style: HapticTapModifier.HapticStyle = .press, action: @escaping () -> Void = {}) -> some View {
        modifier(HapticTapModifier(style: style, action: action))
    }
}
