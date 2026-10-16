import AppKit
import PinFiyCore

final class NotePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func mouseDown(with event: NSEvent) {
        orderFrontRegardless()
        super.mouseDown(with: event)
    }
}

final class PassThroughTextField: NSTextField {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

final class NoteWindowController: NSObject, NSWindowDelegate, NSTextViewDelegate {
    private(set) var note: Note
    var onChange: ((Note) -> Void)?
    var onClose: (() -> Void)?
    var onNew: (() -> Void)?
    var allowClose = false
    private var isApplying = false

    private let panel: NotePanel
    private let content = NoteCanvas()
    private let topBar = ChromeBar()
    private let colorBar = ChromeBar()
    private let textScroll = NSScrollView()
    private let textView = NSTextView()
    private let placeholder = PassThroughTextField(labelWithString: L10n.placeholder)
    private let pinButton = NSButton()
    private let lockButton = NSButton()
    private let closeButton = NSButton()
    private let newButton = NSButton()
    private let smallerButton = NSButton()
    private let largerButton = NSButton()
    private var colorButtons: [ColorSwatch] = []
    private var colorsVisible = false
    private var pointerInside = false
    private var direction: TextDirection = .leftToRight

    init(note: Note) {
        self.note = note
        panel = NotePanel(
            contentRect: NSRect(x: note.x, y: note.y, width: note.width, height: note.height),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        super.init()
        configurePanel()
        configureContent()
        apply(note, moveFrame: true)
    }

    var window: NSWindow { panel }

    func show() {
        panel.orderFrontRegardless()
        panel.makeKey()
    }

    func apply(_ note: Note, moveFrame: Bool = false) {
        self.note = note.normalized()
        isApplying = true
        if textView.string != self.note.text {
            textView.string = self.note.text
        }
        isApplying = false
        applyStyle()
        applyPinPolicy()
        if moveFrame {
            panel.setFrame(
                NSRect(x: self.note.x, y: self.note.y, width: self.note.width, height: self.note.height),
                display: true
            )
        }
        applyLock()
        layoutContent()
    }

    func togglePin() {
        guard !note.locked else { return }
        note.pinned.toggle()
        applyPinPolicy()
        publish()
    }

    func captureFrame() {
        note.x = panel.frame.origin.x
        note.y = panel.frame.origin.y
        note.width = panel.frame.size.width
        note.height = panel.frame.size.height
    }

    private func configurePanel() {
        panel.delegate = self
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        panel.isOpaque = true
        panel.backgroundColor = nsColor(note.colorHex)
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.acceptsMouseMovedEvents = true
        panel.titlebarSeparatorStyle = .none
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        let minimum = NoteMetrics.clamp(width: 0, height: 0)
        panel.contentMinSize = NSSize(width: minimum.width, height: minimum.height)
        panel.contentView = content
        content.onMouseDown = { [weak self] event in
            guard let self else { return }
            self.panel.orderFrontRegardless()
            guard !self.note.locked else { return }
            let point = self.content.convert(event.locationInWindow, from: nil)
            if NoteResizeEdge.at(point, in: self.content.bounds.size) != nil {
                self.resize(with: event)
                return
            }
            self.panel.performDrag(with: event)
        }
    }

    private func configureContent() {
        content.wantsLayer = true
        content.layer?.cornerRadius = 0
        content.layer?.borderWidth = 0
        content.layer?.borderColor = nil
        content.layer?.allowsEdgeAntialiasing = false
        content.layer?.masksToBounds = true

        topBar.wantsLayer = false
        topBar.autoresizingMask = [.width, .minYMargin]
        colorBar.wantsLayer = false
        colorBar.isHidden = true
        colorBar.autoresizingMask = [.width, .maxYMargin]
        textScroll.autoresizingMask = [.width, .height]
        placeholder.autoresizingMask = [.width, .height]
        content.addSubview(topBar)
        content.addSubview(textScroll)
        content.addSubview(placeholder)
        content.addSubview(colorBar)
        content.onMouseMove = { [weak self] point in
            guard let self else { return }
            self.pointerInside = self.content.bounds.contains(point)
            self.updateColorVisibility(at: point)
            self.updateChrome()
            self.applyOpacity()
            self.updateResizeCursor(at: point)
        }
        content.onMouseExit = { [weak self] in
            guard let self else { return }
            let point = self.content.convert(self.panel.mouseLocationOutsideOfEventStream, from: nil)
            self.pointerInside = self.content.bounds.contains(point)
            if self.pointerInside {
                self.updateColorVisibility(at: point)
            } else {
                self.setColorsVisible(false)
            }
            self.updateChrome()
            self.applyOpacity()
            self.clearResizeCursor()
        }

        textScroll.hasVerticalScroller = true
        textScroll.drawsBackground = false
        textScroll.borderType = .noBorder
        textScroll.documentView = textView
        textView.isRichText = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.drawsBackground = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.delegate = self
        textView.textContainerInset = NSSize(width: 4, height: 6)
        placeholder.drawsBackground = false
        placeholder.isBordered = false
        placeholder.isBezeled = false
        placeholder.textColor = nsColor(NotePalette.textHex).withAlphaComponent(0.45)
        placeholder.font = NSFont.systemFont(ofSize: FontSize.standard)

        configureChromeButton(pinButton, symbol: "pin", action: #selector(pinPressed))
        configureChromeButton(lockButton, symbol: "lock.open", action: #selector(lockPressed))
        configureTitleButton(closeButton, title: "×", action: #selector(closePressed))
        configureTitleButton(newButton, title: "+", action: #selector(newPressed))
        configureTitleButton(smallerButton, title: "A−", action: #selector(smallerPressed))
        configureTitleButton(largerButton, title: "A+", action: #selector(largerPressed))
        for button in [pinButton, lockButton, closeButton, newButton, smallerButton, largerButton] {
            topBar.addSubview(button)
        }

        colorButtons = NotePalette.colors.map { color in
            let swatch = ColorSwatch()
            swatch.wantsLayer = true
            swatch.layer?.backgroundColor = nsColor(color.hex).cgColor
            swatch.layer?.cornerRadius = 0
            swatch.layer?.borderWidth = 0
            swatch.hex = color.hex
            swatch.onClick = { [weak self] in
                self?.selectColor(color.hex)
            }
            colorBar.addSubview(swatch)
            return swatch
        }
        content.layoutCallback = { [weak self] in
            self?.layoutContent()
        }
    }

    private func configureChromeButton(_ button: NSButton, symbol: String, action: Selector) {
        button.isBordered = false
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: symbol)
        button.image?.isTemplate = true
        button.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.contentTintColor = nsColor(NotePalette.textHex)
        button.target = self
        button.action = action
    }

    private func configureTitleButton(_ button: NSButton, title: String, action: Selector) {
        button.isBordered = false
        button.title = title
        button.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        button.contentTintColor = nsColor(NotePalette.textHex)
        button.target = self
        button.action = action
    }

    private var isLayingOut = false

    private func layoutContent() {
        guard !isLayingOut, content.bounds.width > 1, content.bounds.height > 1 else { return }
        isLayingOut = true
        defer { isLayingOut = false }

        let bounds = content.bounds
        let barHeight: CGFloat = 36
        let colorHeight: CGFloat = 44
        let textBottom: CGFloat = 8
        topBar.frame = NSRect(x: 0, y: bounds.height - barHeight, width: bounds.width, height: barHeight)
        colorBar.frame = NSRect(x: 10, y: 8, width: max(0, bounds.width - 20), height: colorHeight)
        textScroll.frame = NSRect(
            x: 10,
            y: textBottom,
            width: max(0, bounds.width - 20),
            height: max(40, bounds.height - barHeight - 2 - textBottom)
        )
        placeholder.frame = textScroll.frame.insetBy(dx: 8, dy: 8)
        let textWidth = max(1, textScroll.contentSize.width)
        if abs(textView.frame.width - textWidth) > 0.5 {
            textView.setFrameSize(NSSize(width: textWidth, height: max(textView.frame.height, textScroll.contentSize.height)))
        }
        textView.textContainer?.containerSize = NSSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude)
        layoutChrome()
        layoutColors()
    }

    private var shownResizeCursor: NSCursor?

    private func updateResizeCursor(at point: NSPoint) {
        guard !note.locked, let edge = NoteResizeEdge.at(point, in: content.bounds.size) else {
            clearResizeCursor()
            return
        }
        let cursor = edge.cursor
        guard shownResizeCursor !== cursor else { return }
        cursor.set()
        shownResizeCursor = cursor
    }

    private func clearResizeCursor() {
        guard shownResizeCursor != nil else { return }
        NSCursor.arrow.set()
        shownResizeCursor = nil
    }

    private func resize(with event: NSEvent) {
        panel.perform(NSSelectorFromString("_resizeWithEvent:"), with: event)
        publish()
    }

    private func applyWindowShadow() {
        let selector = NSSelectorFromString("shadowParameters")
        guard panel.responds(to: selector),
              let params = panel.perform(selector)?.takeUnretainedValue() as? NSMutableDictionary else { return }
        for key in [
            "com.apple.WindowShadowInnerRimDensityActive",
            "com.apple.WindowShadowInnerRimDensityInactive",
            "com.apple.WindowShadowInnerRimStyleWhiteActive",
            "com.apple.WindowShadowInnerRimStyleWhiteInactive",
            "com.apple.WindowShadowRimStyleHardActive",
            "com.apple.WindowShadowRimStyleHardInactive",
        ] {
            params[key] = 0
        }
        params["com.apple.WindowShadowRimDensityActive"] = 0.15
        params["com.apple.WindowShadowRimDensityInactive"] = 0.15
        params["com.apple.WindowShadowRadiusActive"] = 18
        params["com.apple.WindowShadowRadiusInactive"] = 18
        params["com.apple.WindowShadowVerticalOffsetActive"] = 4
        params["com.apple.WindowShadowVerticalOffsetInactive"] = 4
        panel.invalidateShadow()
    }

    private func updateChrome() {
        let focused = pointerInside
        let locked = note.locked
        pinButton.isHidden = !focused || locked
        closeButton.isHidden = !focused || locked
        smallerButton.isHidden = !focused || locked
        largerButton.isHidden = !focused || locked
        newButton.isHidden = !focused
        lockButton.isHidden = !focused
        if locked {
            setColorsVisible(false)
        }
    }

    private func updateColorVisibility(at point: NSPoint) {
        guard !note.locked, pointerInside, content.bounds.contains(point) else {
            setColorsVisible(false)
            return
        }
        let revealHeight: CGFloat = colorsVisible ? colorBar.frame.maxY + 6 : 28
        setColorsVisible(point.y >= 0 && point.y <= revealHeight)
    }

    private func setColorsVisible(_ visible: Bool) {
        guard visible != colorsVisible else { return }
        colorsVisible = visible
        colorBar.isHidden = !visible
    }

    private func layoutChrome() {
        let size: CGFloat = 26
        let y = (topBar.bounds.height - size) / 2
        let tools = [closeButton, newButton, largerButton, smallerButton]
        if direction.pinOnTheRight {
            pinButton.frame = NSRect(x: topBar.bounds.width - size - 8, y: y, width: size, height: size)
            lockButton.frame = NSRect(x: topBar.bounds.width - (size * 2) - 10, y: y, width: size, height: size)
            var x: CGFloat = 8
            for button in tools {
                button.frame = NSRect(x: x, y: y, width: size, height: size)
                x += size + 2
            }
        } else {
            pinButton.frame = NSRect(x: 8, y: y, width: size, height: size)
            lockButton.frame = NSRect(x: 8 + size + 2, y: y, width: size, height: size)
            var x = topBar.bounds.width - size - 8
            for button in tools {
                button.frame = NSRect(x: x, y: y, width: size, height: size)
                x -= size + 2
            }
        }
    }

    private func layoutColors() {
        let columns = NotePalette.lightColors.count
        guard columns > 0, !colorButtons.isEmpty else { return }
        let gap: CGFloat = 4
        let width = max(12, (colorBar.bounds.width - gap * CGFloat(columns - 1)) / CGFloat(columns))
        let rows = Int(ceil(Double(colorButtons.count) / Double(columns)))
        let rowHeight = max(12, (colorBar.bounds.height - gap * CGFloat(rows - 1)) / CGFloat(rows))
        for (index, button) in colorButtons.enumerated() {
            let column = index % columns
            let rowFromTop = index / columns
            let y = colorBar.bounds.height - (CGFloat(rowFromTop) + 1) * rowHeight - CGFloat(rowFromTop) * gap
            button.frame = NSRect(x: CGFloat(column) * (width + gap), y: y, width: width, height: rowHeight)
            button.layer?.cornerRadius = 0
            button.layer?.borderWidth = 0
        }
    }

    private func applyStyle() {
        direction = TextDirectionDetector.direction(of: note.text, systemIsArabic: L10n.systemIsArabic)
        let textColor = nsColor(NotePalette.textHex(for: note.colorHex))
        let fill = nsColor(note.colorHex)
        panel.backgroundColor = fill
        content.layer?.backgroundColor = fill.cgColor
        applyWindowShadow()
        textView.font = NSFont.systemFont(ofSize: note.fontSize)
        textView.textColor = textColor
        textView.insertionPointColor = textColor
        placeholder.textColor = textColor.withAlphaComponent(0.45)
        for button in [pinButton, lockButton, closeButton, newButton, smallerButton, largerButton] {
            button.contentTintColor = textColor
        }
        textView.alignment = direction == .rightToLeft ? .right : .left
        textView.baseWritingDirection = direction == .rightToLeft ? .rightToLeft : .leftToRight
        placeholder.alignment = textView.alignment
        placeholder.baseWritingDirection = textView.baseWritingDirection
        placeholder.isHidden = !note.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        content.needsLayout = true
    }

    private func applyPinPolicy() {
        let policy = PinPolicy.policy(pinned: note.pinned)
        panel.level = policy.level == .floating ? .floating : .normal
        var behavior: NSWindow.CollectionBehavior = [.managed, .fullScreenNone]
        if policy.joinsAllSpaces {
            behavior.insert(.canJoinAllSpaces)
        }
        if policy.fullScreenAuxiliary {
            behavior.insert(.fullScreenAuxiliary)
            behavior.remove(.fullScreenNone)
        }
        panel.collectionBehavior = behavior
        let symbol = note.pinned ? "pin.fill" : "pin"
        pinButton.image = NSImage(systemSymbolName: symbol, accessibilityDescription: symbol)
        pinButton.image?.isTemplate = true
        applyOpacity()
    }

    private func applyOpacity() {
        let faded = !pointerInside
        if faded {
            setColorsVisible(false)
        }
        let alpha: CGFloat = faded ? 0.6 : 1
        guard abs(panel.alphaValue - alpha) > 0.01 else { return }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            panel.animator().alphaValue = alpha
        }
    }

    private func applyLock() {
        let locked = note.locked
        textView.isEditable = !locked
        textView.isSelectable = true
        panel.isMovable = !locked
        content.canResize = !locked
        panel.invalidateCursorRects(for: content)
        let minimum = NoteMetrics.clamp(width: 0, height: 0)
        if locked {
            let size = panel.contentRect(forFrameRect: panel.frame).size
            panel.contentMinSize = size
            panel.contentMaxSize = size
        } else {
            panel.contentMinSize = NSSize(width: minimum.width, height: minimum.height)
            panel.contentMaxSize = NSSize(width: 10_000, height: 10_000)
        }
        for button in [pinButton, closeButton, smallerButton, largerButton] {
            button.isEnabled = !locked
            button.alphaValue = locked ? 0.35 : 1
        }
        for swatch in colorButtons {
            swatch.isEnabled = !locked
            swatch.alphaValue = locked ? 0.35 : 1
        }
        let symbol = locked ? "lock.fill" : "lock.open"
        lockButton.image = NSImage(systemSymbolName: symbol, accessibilityDescription: symbol)
        lockButton.image?.isTemplate = true
        lockButton.contentTintColor = nsColor(NotePalette.textHex(for: note.colorHex))
        lockButton.toolTip = locked ? L10n.unlockNote : L10n.lockNote
        lockButton.isEnabled = true
        lockButton.alphaValue = 1
        newButton.isEnabled = true
        newButton.alphaValue = 1
        updateChrome()
    }

    private func publish() {
        captureFrame()
        onChange?(note)
    }

    @objc private func pinPressed() {
        togglePin()
    }

    @objc private func lockPressed() {
        note.locked.toggle()
        applyLock()
        publish()
    }

    @objc private func closePressed() {
        guard !note.locked else { return }
        onClose?()
    }

    @objc private func newPressed() {
        onNew?()
    }

    @objc private func smallerPressed() {
        guard !note.locked else { return }
        note.fontSize = FontSize.clamp(note.fontSize - 1)
        applyStyle()
        publish()
    }

    @objc private func largerPressed() {
        guard !note.locked else { return }
        note.fontSize = FontSize.clamp(note.fontSize + 1)
        applyStyle()
        publish()
    }

    private func selectColor(_ hex: String) {
        guard !note.locked else { return }
        note.colorHex = hex
        applyStyle()
        publish()
    }

    func textDidChange(_ notification: Notification) {
        guard !isApplying else { return }
        if note.locked {
            isApplying = true
            textView.string = note.text
            isApplying = false
            return
        }
        note.text = textView.string
        applyStyle()
        publish()
    }

    func windowDidMove(_ notification: Notification) {
        guard !note.locked else { return }
        publish()
    }

    func windowDidResize(_ notification: Notification) {
        layoutContent()
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        let size = NoteMetrics.clamp(width: panel.frame.width, height: panel.frame.height)
        if abs(panel.frame.width - size.width) > 0.5 || abs(panel.frame.height - size.height) > 0.5 {
            panel.setContentSize(NSSize(width: size.width, height: size.height))
        }
        layoutContent()
        guard !note.locked else { return }
        publish()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if note.locked { return false }
        if allowClose { return true }
        onClose?()
        return false
    }
}

final class ColorSwatch: NSView {
    var hex = ""
    var isEnabled = true
    var onClick: (() -> Void)?

    override func hitTest(_ point: NSPoint) -> NSView? {
        isEnabled ? super.hitTest(point) : nil
    }

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }
}

final class ChromeBar: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        let hit = super.hitTest(point)
        return hit === self ? nil : hit
    }
}

enum NoteResizeEdge {
    case left, right, top, bottom
    case topLeft, topRight, bottomLeft, bottomRight

    static func at(_ point: NSPoint, in size: NSSize, thickness: CGFloat = 8) -> NoteResizeEdge? {
        guard size.width > thickness * 2, size.height > thickness * 2 else { return nil }
        let left = point.x <= thickness
        let right = point.x >= size.width - thickness
        let bottom = point.y <= thickness
        let top = point.y >= size.height - thickness
        switch (left, right, top, bottom) {
        case (true, _, true, _): return .topLeft
        case (_, true, true, _): return .topRight
        case (true, _, _, true): return .bottomLeft
        case (_, true, _, true): return .bottomRight
        case (true, _, _, _): return .left
        case (_, true, _, _): return .right
        case (_, _, true, _): return .top
        case (_, _, _, true): return .bottom
        default: return nil
        }
    }

    var cursor: NSCursor {
        switch self {
        case .left, .right:
            return .resizeLeftRight
        case .top, .bottom:
            return .resizeUpDown
        case .topLeft, .bottomRight, .topRight, .bottomLeft:
            return .crosshair
        }
    }
}

final class NoteCanvas: NSView {
    var onMouseDown: ((NSEvent) -> Void)?
    var onMouseMove: ((NSPoint) -> Void)?
    var onMouseExit: (() -> Void)?
    var layoutCallback: (() -> Void)?
    var canResize = true
    private var tracking: NSTrackingArea?

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        layoutCallback?()
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        if canResize, bounds.contains(local), NoteResizeEdge.at(local, in: bounds.size) != nil {
            return self
        }
        return super.hitTest(point)
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        guard canResize else { return }
        let thickness: CGFloat = 8
        guard bounds.width > thickness * 2, bounds.height > thickness * 2 else { return }
        addCursorRect(NSRect(x: 0, y: thickness, width: thickness, height: bounds.height - thickness * 2), cursor: .resizeLeftRight)
        addCursorRect(NSRect(x: bounds.width - thickness, y: thickness, width: thickness, height: bounds.height - thickness * 2), cursor: .resizeLeftRight)
        addCursorRect(NSRect(x: thickness, y: 0, width: bounds.width - thickness * 2, height: thickness), cursor: .resizeUpDown)
        addCursorRect(NSRect(x: thickness, y: bounds.height - thickness, width: bounds.width - thickness * 2, height: thickness), cursor: .resizeUpDown)
        addCursorRect(NSRect(x: 0, y: bounds.height - thickness, width: thickness, height: thickness), cursor: NoteResizeEdge.topLeft.cursor)
        addCursorRect(NSRect(x: bounds.width - thickness, y: bounds.height - thickness, width: thickness, height: thickness), cursor: NoteResizeEdge.topRight.cursor)
        addCursorRect(NSRect(x: 0, y: 0, width: thickness, height: thickness), cursor: NoteResizeEdge.bottomLeft.cursor)
        addCursorRect(NSRect(x: bounds.width - thickness, y: 0, width: thickness, height: thickness), cursor: NoteResizeEdge.bottomRight.cursor)
    }

    override func layout() {
        super.layout()
        layoutCallback?()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking {
            removeTrackingArea(tracking)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        tracking = area
    }

    override func mouseEntered(with event: NSEvent) {
        reportMove(event)
    }

    override func mouseMoved(with event: NSEvent) {
        reportMove(event)
    }

    override func mouseExited(with event: NSEvent) {
        onMouseExit?()
    }

    override func mouseDown(with event: NSEvent) {
        onMouseDown?(event)
    }

    private func reportMove(_ event: NSEvent) {
        onMouseMove?(convert(event.locationInWindow, from: nil))
    }
}

func nsColor(_ hex: String) -> NSColor {
    var value: UInt64 = 0
    let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    Scanner(string: cleaned).scanHexInt64(&value)
    return NSColor(
        srgbRed: CGFloat((value >> 16) & 0xFF) / 255,
        green: CGFloat((value >> 8) & 0xFF) / 255,
        blue: CGFloat(value & 0xFF) / 255,
        alpha: 1
    )
}
