import Foundation

enum DockGestureKind: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case swipeLeft
    case swipeRight
    case swipeDown
    case swipeUp
    case pinchIn

    var id: String { rawValue }

    func title(
        localeIdentifier: String? = nil,
        preferredLanguages: [String] = Locale.preferredLanguages
    ) -> String {
        switch self {
        case .swipeLeft:
            return L10n.string(
                "settings.dock_gestures.gesture.swipe_left",
                localeIdentifier: localeIdentifier,
                preferredLanguages: preferredLanguages
            )
        case .swipeRight:
            return L10n.string(
                "settings.dock_gestures.gesture.swipe_right",
                localeIdentifier: localeIdentifier,
                preferredLanguages: preferredLanguages
            )
        case .swipeDown:
            return L10n.string(
                "settings.dock_gestures.gesture.swipe_down",
                localeIdentifier: localeIdentifier,
                preferredLanguages: preferredLanguages
            )
        case .swipeUp:
            return L10n.string(
                "settings.dock_gestures.gesture.swipe_up",
                localeIdentifier: localeIdentifier,
                preferredLanguages: preferredLanguages
            )
        case .pinchIn:
            return L10n.string(
                "settings.dock_gestures.gesture.pinch_in",
                localeIdentifier: localeIdentifier,
                preferredLanguages: preferredLanguages
            )
        }
    }
}

enum DockGestureAction: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case minimizeWindow
    case restoreWindow
    case cycleWindowsForward
    case cycleWindowsBackward
    case closeWindow
    case quitApplication

    var id: String { rawValue }

    func title(
        localeIdentifier: String? = nil,
        preferredLanguages: [String] = Locale.preferredLanguages
    ) -> String {
        switch self {
        case .minimizeWindow:
            return L10n.string(
                "action.minimize",
                localeIdentifier: localeIdentifier,
                preferredLanguages: preferredLanguages
            )
        case .restoreWindow:
            return L10n.string(
                "action.restore_window",
                localeIdentifier: localeIdentifier,
                preferredLanguages: preferredLanguages
            )
        case .cycleWindowsForward:
            return L10n.string(
                "action.cycle_same_app_windows_forward",
                localeIdentifier: localeIdentifier,
                preferredLanguages: preferredLanguages
            )
        case .cycleWindowsBackward:
            return L10n.string(
                "action.cycle_same_app_windows_backward",
                localeIdentifier: localeIdentifier,
                preferredLanguages: preferredLanguages
            )
        case .closeWindow:
            return L10n.string(
                "action.close_window",
                localeIdentifier: localeIdentifier,
                preferredLanguages: preferredLanguages
            )
        case .quitApplication:
            return L10n.string(
                "action.quit_application",
                localeIdentifier: localeIdentifier,
                preferredLanguages: preferredLanguages
            )
        }
    }
}

struct DockGestureBinding: Codable, Equatable, Hashable, Sendable {
    let gesture: DockGestureKind
    let action: DockGestureAction
}

enum DockGestureBindings {
    static let defaults: [DockGestureBinding] = [
        DockGestureBinding(gesture: .swipeLeft, action: .cycleWindowsForward),
        DockGestureBinding(gesture: .swipeRight, action: .cycleWindowsBackward),
        DockGestureBinding(gesture: .swipeDown, action: .minimizeWindow),
        DockGestureBinding(gesture: .swipeUp, action: .restoreWindow),
        DockGestureBinding(gesture: .pinchIn, action: .quitApplication),
    ]

    static func fallbackAction(for gesture: DockGestureKind) -> DockGestureAction {
        switch gesture {
        case .swipeLeft:
            return .cycleWindowsForward
        case .swipeRight:
            return .cycleWindowsBackward
        case .swipeDown:
            return .minimizeWindow
        case .swipeUp:
            return .restoreWindow
        case .pinchIn:
            return .quitApplication
        }
    }

    static func action(
        for gesture: DockGestureKind,
        in bindings: [DockGestureBinding]
    ) -> DockGestureAction {
        bindings.first(where: { $0.gesture == gesture })?.action ?? fallbackAction(for: gesture)
    }
}
