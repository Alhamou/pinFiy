import Foundation
import PinFiyCore

enum L10n {
    static var systemIsArabic: Bool {
        Locale.preferredLanguages.first?.hasPrefix("ar") == true
    }

    static var newNote: String { systemIsArabic ? "ملاحظة جديدة" : "New Note" }
    static var closeNote: String { systemIsArabic ? "إغلاق الملاحظة" : "Close Note" }
    static var togglePin: String { systemIsArabic ? "تثبيت" : "Pin" }
    static var settings: String { systemIsArabic ? "الإعدادات" : "Settings" }
    static var quit: String { systemIsArabic ? "إنهاء" : "Quit" }
    static var placeholder: String { systemIsArabic ? "اكتب ملاحظتك" : "Write a note" }
    static var deleteTitle: String { systemIsArabic ? "حذف هذه الملاحظة؟" : "Delete this note?" }
    static var deleteButton: String { systemIsArabic ? "حذف" : "Delete" }
    static var cancelButton: String { systemIsArabic ? "إلغاء" : "Cancel" }
    static var fontSize: String { systemIsArabic ? "حجم الخط الافتراضي" : "Default font size" }
    static var applyToAll: String { systemIsArabic ? "طبّق على كل الملاحظات" : "Apply to all notes" }
    static var openAtLogin: String { systemIsArabic ? "فتح عند تسجيل الدخول" : "Open at login" }
    static var lockNote: String { systemIsArabic ? "قفل الملاحظة" : "Lock note" }
    static var unlockNote: String { systemIsArabic ? "فتح القفل" : "Unlock note" }
    static var loginFailed: String { systemIsArabic ? "تعذر تغيير فتح التطبيق عند تسجيل الدخول." : "Could not change open at login." }

    static func title(for identifier: String) -> String {
        switch identifier {
        case AppCommands.newNote.identifier: return newNote
        case AppCommands.closeNote.identifier: return closeNote
        case AppCommands.togglePin.identifier: return togglePin
        case AppCommands.settings.identifier: return settings
        case AppCommands.quit.identifier: return quit
        default: return identifier
        }
    }
}
