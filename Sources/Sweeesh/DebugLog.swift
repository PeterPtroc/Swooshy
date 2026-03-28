import Foundation
import OSLog

enum DebugLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "Sweeesh"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let settings = Logger(subsystem: subsystem, category: "settings")
    static let hotkeys = Logger(subsystem: subsystem, category: "hotkeys")
    static let dock = Logger(subsystem: subsystem, category: "dock")
    static let windows = Logger(subsystem: subsystem, category: "windows")
    static let accessibility = Logger(subsystem: subsystem, category: "accessibility")

    #if DEBUG
    static func debug(_ logger: Logger, _ message: @autoclosure () -> String) {
        guard isEnabled else { return }
        let rendered = message()
        logger.debug("\(rendered, privacy: .public)")
    }

    static func info(_ logger: Logger, _ message: @autoclosure () -> String) {
        guard isEnabled else { return }
        let rendered = message()
        logger.info("\(rendered, privacy: .public)")
    }

    static func error(_ logger: Logger, _ message: @autoclosure () -> String) {
        guard isEnabled else { return }
        let rendered = message()
        logger.error("\(rendered, privacy: .public)")
    }

    private static var isEnabled: Bool {
        if ProcessInfo.processInfo.environment["SWEEESH_DEBUG_LOGS"] == "1" {
            return true
        }

        return UserDefaults.standard.bool(forKey: "settings.debugLoggingEnabled")
    }
    #else
    static func debug(_ logger: Logger, _ message: @autoclosure () -> String) {}
    static func info(_ logger: Logger, _ message: @autoclosure () -> String) {}
    static func error(_ logger: Logger, _ message: @autoclosure () -> String) {}
    #endif
}
