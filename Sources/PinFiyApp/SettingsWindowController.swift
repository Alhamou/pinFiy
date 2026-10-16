import AppKit
import PinFiyCore

final class SettingsWindowController: NSWindowController {
    var onDefaultFontSize: ((Double) -> Void)?
    var onApplyToAll: (() -> Void)?
    var onOpenAtLogin: ((Bool) -> Void)?
    private let stepper = NSStepper()
    private let valueLabel = NSTextField(labelWithString: "")
    private let loginCheckbox = NSButton(checkboxWithTitle: L10n.openAtLogin, target: nil, action: nil)

    convenience init(fontSize: Double) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 188),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.settings
        self.init(window: window)
        let content = NSView(frame: window.contentView?.bounds ?? .zero)
        window.contentView = content

        let title = NSTextField(labelWithString: L10n.fontSize)
        title.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        title.frame = NSRect(x: 20, y: 144, width: 220, height: 20)
        content.addSubview(title)

        stepper.minValue = FontSize.minimum
        stepper.maxValue = FontSize.maximum
        stepper.increment = 1
        stepper.doubleValue = FontSize.clamp(fontSize)
        stepper.target = self
        stepper.action = #selector(stepped)
        stepper.frame = NSRect(x: 250, y: 140, width: 80, height: 24)
        content.addSubview(stepper)

        valueLabel.frame = NSRect(x: 20, y: 112, width: 120, height: 20)
        valueLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        content.addSubview(valueLabel)
        refreshLabel()

        loginCheckbox.target = self
        loginCheckbox.action = #selector(loginToggled)
        loginCheckbox.frame = NSRect(x: 20, y: 72, width: 320, height: 22)
        content.addSubview(loginCheckbox)

        let apply = NSButton(title: L10n.applyToAll, target: self, action: #selector(applyAll))
        apply.bezelStyle = .rounded
        apply.frame = NSRect(x: 20, y: 20, width: 320, height: 32)
        content.addSubview(apply)
    }

    func show(fontSize: Double, openAtLogin: Bool) {
        stepper.doubleValue = FontSize.clamp(fontSize)
        refreshLabel()
        setOpenAtLogin(openAtLogin)
        window?.level = .floating
        window?.center()
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func setOpenAtLogin(_ enabled: Bool) {
        loginCheckbox.state = enabled ? .on : .off
    }

    @objc private func stepped() {
        let size = FontSize.clamp(stepper.doubleValue)
        stepper.doubleValue = size
        refreshLabel()
        onDefaultFontSize?(size)
    }

    @objc private func applyAll() {
        onApplyToAll?()
    }

    @objc private func loginToggled() {
        onOpenAtLogin?(loginCheckbox.state == .on)
    }

    private func refreshLabel() {
        valueLabel.stringValue = String(Int(stepper.doubleValue))
    }
}
