import AppKit
import Foundation

@MainActor
protocol GestureFeedbackPresenting {
    func show(
        gesture: DockGestureKind,
        gestureTitle: String,
        actionTitle: String,
        anchor: CGPoint?
    )
}

@MainActor
final class GestureFeedbackController: GestureFeedbackPresenting {
    private let settingsStore: SettingsStore
    private let panel: NSPanel
    private let messageLabel = NSTextField(labelWithString: "")
    private let titleLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(labelWithString: "")
    private let glyphView = GestureGlyphView(frame: .zero)
    private let glyphBadgeView = NSView(frame: .zero)
    private var dismissTask: Task<Void, Never>?
    private var currentStyle: GestureHUDStyle?
    private var currentPanelSize = NSSize(width: 208, height: 42)

    private let verticalOffset: CGFloat = 18
    private let sideMargin: CGFloat = 10
    private let dismissalDelay: UInt64 = 700_000_000

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: currentPanelSize),
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

        configureContent(for: settingsStore.gestureHUDStyle)
    }

    func show(
        gesture: DockGestureKind,
        gestureTitle: String,
        actionTitle: String,
        anchor: CGPoint? = nil
    ) {
        configureContent(for: settingsStore.gestureHUDStyle)
        messageLabel.stringValue = "\(gestureTitle) · \(actionTitle)"
        titleLabel.stringValue = actionTitle
        subtitleLabel.stringValue = gestureTitle
        glyphView.gesture = gesture

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

    private func configureContent(for style: GestureHUDStyle) {
        guard currentStyle != style || panel.contentView == nil else { return }

        currentStyle = style
        currentPanelSize = panelSize(for: style)
        panel.setContentSize(currentPanelSize)

        let visualEffectView = NSVisualEffectView(frame: NSRect(origin: .zero, size: currentPanelSize))
        visualEffectView.material = material(for: style)
        visualEffectView.blendingMode = blendingMode(for: style)
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = cornerRadius(for: style)
        visualEffectView.layer?.masksToBounds = true
        visualEffectView.layer?.backgroundColor = backgroundColor(for: style).cgColor
        visualEffectView.layer?.borderColor = borderColor(for: style).cgColor
        visualEffectView.layer?.borderWidth = borderWidth(for: style)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false

        messageLabel.font = .systemFont(ofSize: 12, weight: .medium)
        messageLabel.textColor = .labelColor
        messageLabel.alignment = .center
        messageLabel.maximumNumberOfLines = 1
        messageLabel.lineBreakMode = .byTruncatingMiddle
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: style == .minimal ? 12 : 13, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.maximumNumberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.font = .systemFont(ofSize: 11, weight: .medium)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.maximumNumberOfLines = 1
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        glyphView.translatesAutoresizingMaskIntoConstraints = false
        glyphView.glyphStyle = style == .swishLike ? .trackpad : .minimal
        glyphView.primaryColor = glyphColor(for: style)
        glyphView.secondaryColor = glyphSecondaryColor(for: style)

        glyphBadgeView.translatesAutoresizingMaskIntoConstraints = false
        glyphBadgeView.wantsLayer = true
        glyphBadgeView.layer?.cornerRadius = glyphBadgeCornerRadius(for: style)
        glyphBadgeView.layer?.masksToBounds = true
        glyphBadgeView.layer?.backgroundColor = glyphBadgeBackgroundColor(for: style).cgColor
        glyphBadgeView.layer?.borderColor = glyphBadgeBorderColor(for: style).cgColor
        glyphBadgeView.layer?.borderWidth = glyphBadgeBorderWidth(for: style)
        glyphBadgeView.subviews.forEach { $0.removeFromSuperview() }

        switch style {
        case .classic:
            visualEffectView.addSubview(messageLabel)
            NSLayoutConstraint.activate([
                messageLabel.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor, constant: 12),
                messageLabel.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor, constant: -12),
                messageLabel.topAnchor.constraint(equalTo: visualEffectView.topAnchor, constant: 10),
                messageLabel.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor, constant: -10),
            ])
        case .minimal:
            let row = NSStackView()
            row.orientation = .horizontal
            row.spacing = 10
            row.edgeInsets = NSEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
            row.alignment = .centerY
            row.translatesAutoresizingMaskIntoConstraints = false

            let textStack = NSStackView(views: [titleLabel])
            textStack.orientation = .vertical
            textStack.alignment = .leading
            textStack.translatesAutoresizingMaskIntoConstraints = false

            glyphBadgeView.addSubview(glyphView)
            row.addArrangedSubview(glyphBadgeView)
            row.addArrangedSubview(textStack)
            visualEffectView.addSubview(row)

            NSLayoutConstraint.activate([
                row.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
                row.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
                row.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
                row.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor),
                glyphBadgeView.widthAnchor.constraint(equalToConstant: 24),
                glyphBadgeView.heightAnchor.constraint(equalToConstant: 24),
                glyphView.centerXAnchor.constraint(equalTo: glyphBadgeView.centerXAnchor),
                glyphView.centerYAnchor.constraint(equalTo: glyphBadgeView.centerYAnchor),
                glyphView.widthAnchor.constraint(equalToConstant: 16),
                glyphView.heightAnchor.constraint(equalToConstant: 16),
            ])
        case .swishLike:
            titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
            titleLabel.textColor = NSColor.white.withAlphaComponent(0.96)
            titleLabel.alignment = .center

            subtitleLabel.font = .systemFont(ofSize: 11, weight: .medium)
            subtitleLabel.textColor = NSColor.white.withAlphaComponent(0.64)
            subtitleLabel.alignment = .center

            let textStack = NSStackView(views: [titleLabel, subtitleLabel])
            textStack.orientation = .vertical
            textStack.spacing = 2
            textStack.alignment = .centerX
            textStack.translatesAutoresizingMaskIntoConstraints = false

            glyphBadgeView.addSubview(glyphView)

            let contentStack = NSStackView(views: [glyphBadgeView, textStack])
            contentStack.orientation = .vertical
            contentStack.spacing = 10
            contentStack.alignment = .centerX
            contentStack.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
            contentStack.translatesAutoresizingMaskIntoConstraints = false

            visualEffectView.addSubview(contentStack)

            NSLayoutConstraint.activate([
                contentStack.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
                contentStack.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
                contentStack.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
                contentStack.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor),
                glyphBadgeView.widthAnchor.constraint(equalToConstant: 44),
                glyphBadgeView.heightAnchor.constraint(equalToConstant: 44),
                glyphView.centerXAnchor.constraint(equalTo: glyphBadgeView.centerXAnchor),
                glyphView.centerYAnchor.constraint(equalTo: glyphBadgeView.centerYAnchor),
                glyphView.widthAnchor.constraint(equalToConstant: 26),
                glyphView.heightAnchor.constraint(equalToConstant: 26),
            ])
        }

        panel.contentView = visualEffectView
        panel.alphaValue = 0
    }

    private func frame(for anchorPoint: CGPoint) -> NSRect {
        let screen = NSScreen.screens.first(where: { $0.frame.contains(anchorPoint) }) ?? NSScreen.main ?? NSScreen.screens.first
        let visibleFrame = screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero

        let width = currentPanelSize.width
        let height = currentPanelSize.height
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

    private func panelSize(for style: GestureHUDStyle) -> NSSize {
        switch style {
        case .classic:
            return NSSize(width: 208, height: 42)
        case .minimal:
            return NSSize(width: 182, height: 40)
        case .swishLike:
            return NSSize(width: 132, height: 98)
        }
    }

    private func cornerRadius(for style: GestureHUDStyle) -> CGFloat {
        switch style {
        case .classic:
            return 14
        case .minimal:
            return 12
        case .swishLike:
            return 26
        }
    }

    private func backgroundColor(for style: GestureHUDStyle) -> NSColor {
        switch style {
        case .classic, .minimal:
            return .clear
        case .swishLike:
            return NSColor(calibratedWhite: 0.06, alpha: 0.80)
        }
    }

    private func borderColor(for style: GestureHUDStyle) -> NSColor {
        switch style {
        case .classic, .minimal:
            return .clear
        case .swishLike:
            return NSColor.white.withAlphaComponent(0.16)
        }
    }

    private func borderWidth(for style: GestureHUDStyle) -> CGFloat {
        switch style {
        case .classic, .minimal:
            return 0
        case .swishLike:
            return 0.8
        }
    }

    private func material(for style: GestureHUDStyle) -> NSVisualEffectView.Material {
        switch style {
        case .classic, .minimal:
            return .hudWindow
        case .swishLike:
            return .menu
        }
    }

    private func blendingMode(for style: GestureHUDStyle) -> NSVisualEffectView.BlendingMode {
        switch style {
        case .classic, .minimal:
            return .behindWindow
        case .swishLike:
            return .withinWindow
        }
    }

    private func glyphColor(for style: GestureHUDStyle) -> NSColor {
        switch style {
        case .classic, .minimal:
            return NSColor.labelColor.withAlphaComponent(0.9)
        case .swishLike:
            return NSColor.white.withAlphaComponent(0.98)
        }
    }

    private func glyphSecondaryColor(for style: GestureHUDStyle) -> NSColor {
        switch style {
        case .classic, .minimal:
            return NSColor.labelColor.withAlphaComponent(0.16)
        case .swishLike:
            return NSColor.white.withAlphaComponent(0.18)
        }
    }

    private func glyphBadgeBackgroundColor(for style: GestureHUDStyle) -> NSColor {
        switch style {
        case .classic:
            return .clear
        case .minimal:
            return NSColor.labelColor.withAlphaComponent(0.08)
        case .swishLike:
            return NSColor.white.withAlphaComponent(0.08)
        }
    }

    private func glyphBadgeBorderColor(for style: GestureHUDStyle) -> NSColor {
        switch style {
        case .classic:
            return .clear
        case .minimal:
            return NSColor.labelColor.withAlphaComponent(0.08)
        case .swishLike:
            return NSColor.white.withAlphaComponent(0.12)
        }
    }

    private func glyphBadgeBorderWidth(for style: GestureHUDStyle) -> CGFloat {
        switch style {
        case .classic:
            return 0
        case .minimal:
            return 0.5
        case .swishLike:
            return 1
        }
    }

    private func glyphBadgeCornerRadius(for style: GestureHUDStyle) -> CGFloat {
        switch style {
        case .classic:
            return 0
        case .minimal:
            return 8
        case .swishLike:
            return 14
        }
    }
}

private final class GestureGlyphView: NSView {
    enum Style {
        case minimal
        case trackpad
    }

    var gesture: DockGestureKind = .swipeLeft {
        didSet { needsDisplay = true }
    }

    var glyphStyle: Style = .minimal {
        didSet { needsDisplay = true }
    }

    var primaryColor: NSColor = NSColor.labelColor.withAlphaComponent(0.9) {
        didSet { needsDisplay = true }
    }

    var secondaryColor: NSColor = NSColor.labelColor.withAlphaComponent(0.16) {
        didSet { needsDisplay = true }
    }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        context.saveGState()
        defer { context.restoreGState() }

        switch glyphStyle {
        case .minimal:
            drawMinimalGlyph(in: bounds)
        case .trackpad:
            drawTrackpadGlyph(in: bounds)
        }
    }

    private func drawMinimalGlyph(in rect: NSRect) {
        let glyphRect = sanitizedRect(from: rect.insetBy(dx: 2, dy: 2), minimumSize: 8)
        guard glyphRect.isEmpty == false else { return }

        let path = gestureArrowPath(in: glyphRect, lineWidth: 2.2)
        primaryColor.setStroke()
        path.stroke()
    }

    private func drawTrackpadGlyph(in rect: NSRect) {
        let trackpadRect = sanitizedRect(from: rect.insetBy(dx: 3, dy: 5), minimumSize: 18)
        guard trackpadRect.isEmpty == false else { return }

        let platePath = NSBezierPath(roundedRect: trackpadRect, xRadius: 8, yRadius: 8)
        secondaryColor.setFill()
        platePath.fill()

        secondaryColor.withAlphaComponent(0.85).setStroke()
        platePath.lineWidth = 1
        platePath.stroke()

        let arrowRect = sanitizedRect(from: trackpadRect.insetBy(dx: 4, dy: 4), minimumSize: 10)
        guard arrowRect.isEmpty == false else { return }

        let arrow = gestureArrowPath(in: arrowRect, lineWidth: 2.3)
        primaryColor.setStroke()
        arrow.stroke()
    }

    private func gestureArrowPath(in rect: NSRect, lineWidth: CGFloat) -> NSBezierPath {
        let rect = rect.standardized
        let path = NSBezierPath()
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.lineWidth = lineWidth

        switch gesture {
        case .swipeLeft:
            addLine(to: path, from: CGPoint(x: rect.maxX, y: rect.midY), to: CGPoint(x: rect.minX + 4, y: rect.midY))
            addLine(to: path, from: CGPoint(x: rect.minX + 4, y: rect.midY), to: CGPoint(x: rect.minX + 10, y: rect.midY - 5))
            addLine(to: path, from: CGPoint(x: rect.minX + 4, y: rect.midY), to: CGPoint(x: rect.minX + 10, y: rect.midY + 5))
        case .swipeRight:
            addLine(to: path, from: CGPoint(x: rect.minX, y: rect.midY), to: CGPoint(x: rect.maxX - 4, y: rect.midY))
            addLine(to: path, from: CGPoint(x: rect.maxX - 4, y: rect.midY), to: CGPoint(x: rect.maxX - 10, y: rect.midY - 5))
            addLine(to: path, from: CGPoint(x: rect.maxX - 4, y: rect.midY), to: CGPoint(x: rect.maxX - 10, y: rect.midY + 5))
        case .swipeUp:
            addLine(to: path, from: CGPoint(x: rect.midX, y: rect.maxY), to: CGPoint(x: rect.midX, y: rect.minY + 4))
            addLine(to: path, from: CGPoint(x: rect.midX, y: rect.minY + 4), to: CGPoint(x: rect.midX - 5, y: rect.minY + 10))
            addLine(to: path, from: CGPoint(x: rect.midX, y: rect.minY + 4), to: CGPoint(x: rect.midX + 5, y: rect.minY + 10))
        case .swipeDown:
            addLine(to: path, from: CGPoint(x: rect.midX, y: rect.minY), to: CGPoint(x: rect.midX, y: rect.maxY - 4))
            addLine(to: path, from: CGPoint(x: rect.midX, y: rect.maxY - 4), to: CGPoint(x: rect.midX - 5, y: rect.maxY - 10))
            addLine(to: path, from: CGPoint(x: rect.midX, y: rect.maxY - 4), to: CGPoint(x: rect.midX + 5, y: rect.maxY - 10))
        case .pinchIn:
            addLine(to: path, from: CGPoint(x: rect.minX + 1, y: rect.minY + 1), to: CGPoint(x: rect.midX - 2, y: rect.midY - 2))
            addLine(to: path, from: CGPoint(x: rect.maxX - 1, y: rect.minY + 1), to: CGPoint(x: rect.midX + 2, y: rect.midY - 2))
            addLine(to: path, from: CGPoint(x: rect.minX + 1, y: rect.maxY - 1), to: CGPoint(x: rect.midX - 2, y: rect.midY + 2))
            addLine(to: path, from: CGPoint(x: rect.maxX - 1, y: rect.maxY - 1), to: CGPoint(x: rect.midX + 2, y: rect.midY + 2))
        }

        return path
    }

    private func sanitizedRect(from rect: NSRect, minimumSize: CGFloat) -> NSRect {
        guard
            rect.origin.x.isFinite,
            rect.origin.y.isFinite,
            rect.size.width.isFinite,
            rect.size.height.isFinite
        else {
            return .zero
        }

        let standardized = rect.standardized
        guard standardized.width >= minimumSize, standardized.height >= minimumSize else {
            return .zero
        }

        return standardized
    }

    private func addLine(to path: NSBezierPath, from start: CGPoint, to end: CGPoint) {
        guard
            start.x.isFinite,
            start.y.isFinite,
            end.x.isFinite,
            end.y.isFinite
        else {
            return
        }

        path.move(to: start)
        path.line(to: end)
    }
}
