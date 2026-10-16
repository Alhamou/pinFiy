import AppKit
import PinFiyCore

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let store: NoteStore
    private var document: NoteDocument
    private var controllers: [UUID: NoteWindowController] = [:]
    private var settings: SettingsWindowController?
    private var saveTimer: Timer?
    private var statusItem: NSStatusItem?
    private var loginMenuItem: NSMenuItem?
    private let saveDelay: TimeInterval = 0.4

    override init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        store = NoteStore(directory: support.appendingPathComponent("pinFiy", isDirectory: true))
        document = NoteDocument(defaultFontSize: FontSize.standard, notes: [])
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        installMenu()
        installStatusItem()
        let screen = mainScreen()
        document = store.load(mainScreen: screen)
        document.notes = document.notes.map { clamped($0, on: screen) }
        for note in document.notes {
            show(note)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        saveNow()
        return .terminateNow
    }

    func applicationWillTerminate(_ notification: Notification) {
        saveNow()
    }

    private func installMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem()
        main.addItem(appItem)
        let menu = NSMenu()
        for command in AppCommands.all {
            let item = NSMenuItem(
                title: L10n.title(for: command.identifier),
                action: selector(for: command.identifier),
                keyEquivalent: command.keyEquivalent
            )
            item.keyEquivalentModifierMask = .command
            if command.identifier == AppCommands.quit.identifier {
                item.target = NSApp
            } else {
                item.target = self
            }
            menu.addItem(item)
        }
        appItem.submenu = menu
        NSApp.mainMenu = main
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            let image = NSImage(systemSymbolName: "pin.fill", accessibilityDescription: "pinFiy")
            image?.isTemplate = true
            image?.size = NSSize(width: 15, height: 15)
            button.image = image
        }
        let menu = NSMenu()
        menu.delegate = self
        let newNote = NSMenuItem(title: L10n.newNote, action: #selector(newNoteAction), keyEquivalent: "")
        newNote.target = self
        menu.addItem(newNote)
        menu.addItem(.separator())
        let settingsItem = NSMenuItem(title: L10n.settings, action: #selector(settingsAction), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        let login = NSMenuItem(title: L10n.openAtLogin, action: #selector(toggleLoginFromMenu), keyEquivalent: "")
        login.target = self
        menu.addItem(login)
        loginMenuItem = login
        menu.addItem(.separator())
        let quit = NSMenuItem(title: L10n.quit, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        quit.target = NSApp
        menu.addItem(quit)
        item.menu = menu
        statusItem = item
    }

    func menuWillOpen(_ menu: NSMenu) {
        loginMenuItem?.state = LoginItem.isEnabled ? .on : .off
    }

    @objc private func toggleLoginFromMenu() {
        setOpenAtLogin(!LoginItem.isEnabled)
    }

    private func setOpenAtLogin(_ enabled: Bool) {
        do {
            try LoginItem.setEnabled(enabled)
        } catch {
            let alert = NSAlert()
            alert.messageText = L10n.loginFailed
            alert.alertStyle = .warning
            alert.window.level = .floating
            alert.runModal()
        }
        let actual = LoginItem.isEnabled
        loginMenuItem?.state = actual ? .on : .off
        settings?.setOpenAtLogin(actual)
    }

    private func selector(for identifier: String) -> Selector {
        switch identifier {
        case AppCommands.newNote.identifier:
            return #selector(newNoteAction)
        case AppCommands.closeNote.identifier:
            return #selector(closeNoteAction)
        case AppCommands.togglePin.identifier:
            return #selector(togglePinAction)
        case AppCommands.settings.identifier:
            return #selector(settingsAction)
        case AppCommands.quit.identifier:
            return #selector(NSApplication.terminate(_:))
        default:
            return #selector(newNoteAction)
        }
    }

    @objc private func newNoteAction() {
        createNote(beside: frontController()?.note)
    }

    @objc private func closeNoteAction() {
        guard let controller = frontController() else { return }
        close(controller)
    }

    @objc private func togglePinAction() {
        frontController()?.togglePin()
    }

    @objc private func settingsAction() {
        if settings == nil {
            let controller = SettingsWindowController(fontSize: document.defaultFontSize)
            controller.onDefaultFontSize = { [weak self] size in
                self?.document.updateDefaultFontSize(size)
                self?.scheduleSave()
            }
            controller.onApplyToAll = { [weak self] in
                guard let self else { return }
                self.document.applyDefaultFontSizeToAllNotes()
                for note in self.document.notes {
                    self.controllers[note.id]?.apply(note)
                }
                self.scheduleSave()
            }
            controller.onOpenAtLogin = { [weak self] enabled in
                self?.setOpenAtLogin(enabled)
            }
            settings = controller
        }
        settings?.show(fontSize: document.defaultFontSize, openAtLogin: LoginItem.isEnabled)
    }

    private func createNote(beside existing: Note?) {
        let note = document.makingNote(beside: existing, on: mainScreen())
        document.notes.append(note)
        show(note)
        scheduleSave()
    }

    private func show(_ note: Note) {
        let controller = NoteWindowController(note: note)
        controller.onChange = { [weak self] updated in
            self?.replace(updated)
        }
        controller.onClose = { [weak self] in
            self?.close(controller)
        }
        controller.onNew = { [weak self] in
            self?.createNote(beside: controller.note)
        }
        controllers[note.id] = controller
        controller.show()
    }

    private func replace(_ note: Note) {
        guard let index = document.notes.firstIndex(where: { $0.id == note.id }) else { return }
        document.notes[index] = note
        scheduleSave()
    }

    private func close(_ controller: NoteWindowController) {
        guard !controller.note.locked else { return }
        let note = controller.note
        if NoteClosing.decision(text: note.text) == .needsConfirmation {
            let alert = NSAlert()
            alert.messageText = L10n.deleteTitle
            alert.addButton(withTitle: L10n.deleteButton)
            alert.addButton(withTitle: L10n.cancelButton)
            alert.window.level = .floating
            guard alert.runModal() == .alertFirstButtonReturn else { return }
        }
        document = NoteClosing.applyingClose(
            document: document,
            id: note.id,
            confirmed: true,
            on: mainScreen()
        )
        controller.allowClose = true
        controller.window.close()
        controllers[note.id] = nil
        for created in document.notes where controllers[created.id] == nil {
            show(created)
        }
        scheduleSave()
    }

    private func frontController() -> NoteWindowController? {
        if let key = NSApp.keyWindow,
           let match = controllers.values.first(where: { $0.window === key }) {
            return match
        }
        return controllers.values.first(where: { $0.window.isVisible })
    }

    private func scheduleSave() {
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: saveDelay, repeats: false) { [weak self] _ in
            self?.saveNow()
        }
    }

    private func saveNow() {
        saveTimer?.invalidate()
        saveTimer = nil
        for controller in controllers.values {
            controller.captureFrame()
            if let index = document.notes.firstIndex(where: { $0.id == controller.note.id }) {
                document.notes[index] = controller.note
            }
        }
        do {
            try store.save(document)
        } catch {
            FileHandle.standardError.write(Data("pinFiy save failed: \(error)\n".utf8))
        }
    }

    private func mainScreen() -> ScreenRect {
        let frame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        return ScreenRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: frame.height)
    }

    private func clamped(_ note: Note, on main: ScreenRect) -> Note {
        let screens = NSScreen.screens.map { screen in
            ScreenRect(
                x: screen.visibleFrame.origin.x,
                y: screen.visibleFrame.origin.y,
                width: screen.visibleFrame.width,
                height: screen.visibleFrame.height
            )
        }
        let visible = ScreenLayout.visibleFrame(
            for: ScreenRect(x: note.x, y: note.y, width: note.width, height: note.height),
            screens: screens.isEmpty ? [main] : screens,
            mainScreen: main
        )
        var copy = note
        copy.x = visible.x
        copy.y = visible.y
        copy.width = visible.width
        copy.height = visible.height
        return copy
    }
}
