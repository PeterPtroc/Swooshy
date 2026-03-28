import Foundation

enum GestureHUDStyle: String, CaseIterable, Codable, Identifiable, Sendable {
    case classic
    case minimal
    case swishLike

    var id: String { rawValue }

    func title(
        localeIdentifier: String? = nil,
        preferredLanguages: [String] = Locale.preferredLanguages
    ) -> String {
        switch self {
        case .classic:
            return L10n.string(
                "settings.gesture_hud.style.classic",
                localeIdentifier: localeIdentifier,
                preferredLanguages: preferredLanguages
            )
        case .minimal:
            return L10n.string(
                "settings.gesture_hud.style.minimal",
                localeIdentifier: localeIdentifier,
                preferredLanguages: preferredLanguages
            )
        case .swishLike:
            return L10n.string(
                "settings.gesture_hud.style.swish_like",
                localeIdentifier: localeIdentifier,
                preferredLanguages: preferredLanguages
            )
        }
    }
}
