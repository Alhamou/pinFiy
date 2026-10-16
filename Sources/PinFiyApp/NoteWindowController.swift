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
    private let content = NoteMarginView()
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
    private var colorButtons: [NSButton] = []
    private var direction: TextDirection = .leftToRight

    init(note: Note) {
        self.note = note
        panel = NotePanel(
            contentRect: NSRect(x: note.x, y: note.y, width: note.width, height: note.height),
            styleMask: [.titled, .resizable, .fullSizeContentView],
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
            panel.setFrame(NSRect(x: self.note.x, y: self.note.y, width: self.note.width, height: self.note.height), display: true)
        }
        applyLock()
        content.needsLayout = true
    }

    func togglePin() {
        guard !note.locked else { return }
        note.pinned.toggle()
        applyPinPolicy()
        publish()
    }

    func captureFrame() {
        let frame = panel.frame
        note.x = frame.origin.x
        note.y = frame.origin.y
        note.width = frame.size.width
        note.height = frame.size.height
    }

    private func configurePanel() {
        panel.delegate = self
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.titlebarSeparatorStyle = .none
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        let minimum = NoteMetrics.clamp(width: 0, height: 0)
        panel.contentMinSize = NSSize(width: minimum.width, height: minimum.height)
        panel.contentView = content
        content.onMarginMouseDown = { [weak self] event in
            guard let self else { return }
            self.panel.orderFrontRegardless()
            guard !self.note.locked else { return }
            self.panel.performDrag(with: event)
        }
    }

    private func configureContent() {
        content.wantsLayer = true
        content.layer?.cornerRadius = 14
        content.layer?.masksToBounds = true

        topBar.wantsLayer = false
        colorBar.wantsLayer = false
        content.addSubview(topBar)
        content.addSubview(colorBar)
        content.addSubview(textScroll)
        content.addSubview(placeholder)

        textScroll.hasVerticalScroller = true
        textScroll.drawsBackground = false
        textScroll.borderType = .noBorder
        textScroll.documentView = textView
        textView.isRichText = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 240, height: CGFloat.greatestFiniteMagnitude)
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
            let button = NSButton()
            button.title = ""
            button.alternateTitle = ""
            button.isBordered = false
            button.focusRingType = .none
            button.wantsLayer = true
            button.layer?.backgroundColor = nsColor(color.hex).cgColor
            button.layer?.cornerRadius = 8
            button.layer?.borderWidth = 1
            button.layer?.borderColor = nsColor(color.textHex).withAlphaComponent(0.45).cgColor
            button.target = self
            button.action = #selector(colorPressed(_:))
            button.identifier = NSUserInterfaceItemIdentifier(color.hex)
            colorBar.addSubview(button)
            return button
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

    private func layoutContent() {
        let bounds = content.bounds
        let barHeight: CGFloat = 36
        let colorHeight: CGFloat = 56
        topBar.frame = NSRect(x: 0, y: bounds.height - barHeight, width: bounds.width, height: barHeight)
        colorBar.frame = NSRect(x: 10, y: 8, width: bounds.width - 20, height: colorHeight - 12)
        let textTop = barHeight + 2
        textScroll.frame = NSRect(
            x: 10,
            y: colorHeight,
            width: bounds.width - 20,
            height: max(40, bounds.height - textTop - colorHeight)
        )
        placeholder.frame = textScroll.frame.insetBy(dx: 8, dy: 8)
        layoutChrome()
        layoutColors()
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
            button.layer?.cornerRadius = min(8, width / 2)
        }
    }

    private func applyStyle() {
        direction = TextDirectionDetector.direction(of: note.text, systemIsArabic: L10n.systemIsArabic)
        let textColor = nsColor(NotePalette.textHex(for: note.colorHex))
        content.layer?.backgroundColor = nsColor(note.colorHex).cgColor
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
        for button in colorButtons {
            let selected = button.identifier?.rawValue.caseInsensitiveCompare(note.colorHex) == .orderedSame
            button.layer?.borderWidth = selected ? 2 : 1
        }
        content.needsLayout = true
    }

    private func applyPinPolicy() {
        let policy = PinPolicy.policy(pinned: note.pinned)
        panel.level = policy.level == .floating ? .floating : .normal
        if policy.joinsAllSpaces {
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        } else {
            panel.collectionBehavior = [.managed]
        }
        let symbol = note.pinned ? "pin.fill" : "pin"
        pinButton.image = NSImage(systemSymbolName: symbol, accessibilityDescription: symbol)
        pinButton.image?.isTemplate = true
    }

    private func applyLock() {
        let locked = note.locked
        textView.isEditable = !locked
        textView.isSelectable = true
        panel.isMovable = !locked
        let minimum = NoteMetrics.clamp(width: 0, height: 0)
        if locked {
            let size = panel.contentRect(forFrameRect: panel.frame).size
            panel.contentMinSize = size
            panel.contentMaxSize = size
        } else {
            panel.contentMinSize = NSSize(width: minimum.width, height: minimum.height)
            panel.contentMaxSize = NSSize(width: 10_000, height: 10_000)
        }
        for button in [pinButton, closeButton, smallerButton, largerButton] + colorButtons {
            button.isEnabled = !locked
            button.alphaValue = locked ? 0.35 : 1
        }
        let symbol = locked ? "lock.fill" : "lock.open"
        lockButton.image = NSImage(systemSymbolName: symbol, accessibilityDescription: symbol)
        lockButton.image?.isTemplate = true
        lockButton.contentTintColor = nsColor(NotePalette.textHex(for: note.colorHex))
        lockButton.toolTip = locked ? L10n.unlockNote : L10n.lockNote
        lockButton.isEnabled = true
        lockButton.alphaValue = 1
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

    @objc private func colorPressed(_ sender: NSButton) {
        guard !note.locked, let hex = sender.identifier?.rawValue else { return }
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

    func windowDidEndLiveResize(_ notification: Notification) {
        guard !note.locked else { return }
        let size = NoteMetrics.clamp(width: panel.frame.width, height: panel.frame.height)
        if panel.frame.width < size.width || panel.frame.height < size.height {
            panel.setContentSize(NSSize(width: size.width, height: size.height))
        }
        publish()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if note.locked { return false }
        if allowClose { return true }
        onClose?()
        return false
    }
}

final class ChromeBar: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        let hit = super.hitTest(point)
        return hit === self ? nil : hit
    }
}

final class NoteMarginView: NSView {
    var onMarginMouseDown: ((NSEvent) -> Void)?
    var layoutCallback: (() -> Void)?

    override func layout() {
        super.layout()
        layoutCallback?()
    }

    override func mouseDown(with event: NSEvent) {
        onMarginMouseDown?(event)
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
