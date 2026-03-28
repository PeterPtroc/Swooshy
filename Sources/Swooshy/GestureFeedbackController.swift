import AppKit
import Foundation

@MainActor
protocol GestureFeedbackPresenting {
    func show(
        gestureTitle: String,
        actionTitle: String,
        anchor: CGPoint?
    )
}

@MainActor
final class GestureFeedbackController: GestureFeedbackPresenting {
    private let panel: NSPanel
    private let messageLabel = NSTextField(labelWithString: "")
    private var dismissTask: Task<Void, Never>?

    private let panelSize = NSSize(width: 208, height: 42)
    private let verticalOffset: CGFloat = 18
    private let sideMargin: CGFloat = 10
    private let dismissalDelay: UInt64 = 700_000_000

    init() {
        panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.nonactivatingPanel, .hudWindow, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        configureContent()
    }

    func show(
        gestureTitle: String,
        actionTitle: String,
        anchor: CGPoint? = nil
    ) {
        messageLabel.stringValue = "\(gestureTitle) · \(actionTitle)"

        let anchorPoint = anchor ?? NSEvent.mouseLocation
        panel.setFrame(frame(for: anchorPoint), display: false)

        dismissTask?.cancel()
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }

        let delay = self.dismissalDelay

        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                self?.hide()
            }
        }
    }

    private func configureContent() {
        let visualEffectView = NSVisualEffectView(frame: NSRect(origin: .zero, size: panelSize))
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 14
        visualEffectView.layer?.masksToBounds = true
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false

        messageLabel.font = .systemFont(ofSize: 12, weight: .medium)
        messageLabel.textColor = .labelColor
        messageLabel.alignment = .center
        messageLabel.maximumNumberOfLines = 1
        messageLabel.lineBreakMode = .byTruncatingMiddle
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        visualEffectView.addSubview(messageLabel)
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor, constant: -12),
            messageLabel.topAnchor.constraint(equalTo: visualEffectView.topAnchor, constant: 10),
            messageLabel.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor, constant: -10),
        ])

        panel.contentView = visualEffectView
        panel.alphaValue = 0
    }

    private func frame(for anchorPoint: CGPoint) -> NSRect {
        let screen = NSScreen.screens.first(where: { $0.frame.contains(anchorPoint) }) ?? NSScreen.main ?? NSScreen.screens.first
        let visibleFrame = screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero

        let width = panelSize.width
        let height = panelSize.height
        let desiredX = anchorPoint.x - (width / 2)
        let desiredY = anchorPoint.y + verticalOffset

        let minX = visibleFrame.minX + sideMargin
        let maxX = visibleFrame.maxX - width - sideMargin
        let minY = visibleFrame.minY + sideMargin
        let maxY = visibleFrame.maxY - height - sideMargin

        let clampedX = min(max(desiredX, minX), maxX)
        let clampedY = min(max(desiredY, minY), maxY)

        return NSRect(x: clampedX, y: clampedY, width: width, height: height)
    }

    private func hide() {
        dismissTask?.cancel()
        dismissTask = nil

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        } completionHandler: {
            Task { @MainActor in
                self.panel.orderOut(nil)
            }
        }
    }
}
