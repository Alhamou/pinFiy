<p align="center">
  <img src="docs/pinFiy-512.png" width="128" height="128" alt="pinFiy">
</p>

<p align="center">
  ملاحظات ملونة على الماك، وأيقونة دبوس صغيرة في الشريط العلوي.
  <br>
  Colored sticky notes for the Mac, with a small pin in the menu bar.
</p>

<p align="center">
  <a href="LICENSE">MIT</a>
  ·
  macOS 13+
  ·
  <a href="CONTRIBUTING.md">Contributing</a>
  ·
  <a href="SECURITY.md">Security</a>
  ·
  <a href="PRIVACY.md">Privacy</a>
</p>

# pinFiy

ملاحظات ملونة على الماك. كل ملاحظة نافذة مستقلة. العربية تُحاذى من اليمين إلى اليسار، والإنجليزية من اليسار إلى اليمين، حسب أول حرف قوي في النص. الدبوس يُبقي الملاحظة فوق النوافذ العادية دون تغطية شريط القائمة. التطبيق نفسه يبقى أيقونة دبوس في الشريط العلوي ولا يظهر في الشريط الجانبي.

صورة المستودع بحجم 512×512 بكسل موجودة في [`docs/pinFiy-512.png`](docs/pinFiy-512.png). ارفع هذا الملف صورةً للمستودع من إعدادات GitHub.

## المزايا

- عشر ألوان فاتحة وعشر ألوان داكنة. الافتراضي كهرماني دافئ `#F3C15B`. النص الداكن على الألوان الفاتحة، والنص الفاتح على الألوان الداكنة.
- حجم الخط من 12 إلى 36، لكل ملاحظة، ومن الإعدادات للملاحظات الجديدة أو لكل الملاحظات.
- قفل الملاحظة يمنع تعديل النص واللون والحجم والمكان والإغلاق.
- الحفظ المحلي في `~/Library/Application Support/pinFiy/notes.json` مع نسخة احتياطية.
- اختصارات لوحة المفاتيح، وتأكيد قبل حذف ملاحظة فيها نص.
- خيار فتح التطبيق عند تسجيل الدخول من الإعدادات أو من قائمة الدبوس.
- بلا حساب، وبلا مزامنة سحابية، وبلا شبكة.

## المتطلبات

- macOS 13 أو أحدث
- Swift 5.9 أو أحدث، والمرفق مع Xcode يكفي

## البناء والاختبار

```bash
git clone https://github.com/Alhamou/pinFiy.git
cd pinFiy
swift test
./scripts/build-app.sh
open PinFiy.app
```

`./scripts/build-app.sh` يبني `PinFiy.app` بالمعرّف `app.pinfiy.PinFiy`، ويضع الأيقونة، ويوقّع الحزمة توقيعًا محليًا. هذا ليس توقيع Apple Developer ولا نشرًا على App Store.

## الاستخدام

| الإجراء | الطريقة |
| --- | --- |
| ملاحظة جديدة | زر `+` أو ⌘N أو قائمة الدبوس |
| إغلاق | زر `×` أو ⌘W. النص غير الفارغ يطلب تأكيدًا |
| تثبيت فوق النوافذ | زر الدبوس أو ⌘P |
| قفل التعديل | زر القفل على الملاحظة |
| لون وحجم الخط | شريط الألوان و`A−` / `A+` |
| الإعدادات | ⌘, أو قائمة الدبوس |
| إنهاء | ⌘Q أو قائمة الدبوس |

اتجاه الدبوس يتبع اتجاه النص: يمينًا للعربية ويسارًا للإنجليزية.

## هيكل المشروع

```text
Package.swift          Swift Package
Sources/PinFiyCore     النموذج والحفظ بلا AppKit
Sources/PinFiyApp      نوافذ الملاحظات وشريط القائمة
Tests/PinFiyCoreTests  اختبارات XCTest
scripts/build-app.sh   بناء PinFiy.app
docs/pinFiy-512.png    شعار 512×512
```

## المساهمة

اقرأ [CONTRIBUTING.md](CONTRIBUTING.md) و[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md). الإبلاغ عن ثغرة أمنية يتم بشكل خاص كما في [SECURITY.md](SECURITY.md).

## الترخيص

[MIT](LICENSE) © 2026 pinFiy contributors

---

# pinFiy

Colored sticky notes for the Mac. Each note is its own window. Arabic text runs right to left and English text runs left to right, based on the first strong character. Pin keeps a note above normal windows and does not cover the menu bar. The app itself stays as a pin in the menu bar and does not appear in the Dock.

The repository image is a 512×512 PNG at [`docs/pinFiy-512.png`](docs/pinFiy-512.png). Upload that file as the GitHub repository image.

## Features

- Ten light colors and ten dark colors. The default is warm amber `#F3C15B`. Dark text sits on light colors, and light text sits on dark colors.
- Font size from 12 to 36, per note, and from Settings for new notes or for every note.
- Locking a note blocks text, color, size, position, and closing.
- Local storage at `~/Library/Application Support/pinFiy/notes.json`, with a backup.
- Keyboard shortcuts, and confirmation before deleting a note that has text.
- Open at login from Settings or from the pin menu.
- No account, no cloud sync, and no network access.

## Requirements

- macOS 13 or later
- Swift 5.9 or later, including the toolchain shipped with Xcode

## Build and test

```bash
git clone https://github.com/Alhamou/pinFiy.git
cd pinFiy
swift test
./scripts/build-app.sh
open PinFiy.app
```

`./scripts/build-app.sh` builds `PinFiy.app` with bundle id `app.pinfiy.PinFiy`, installs the icon, and ad-hoc signs the bundle. That is not an Apple Developer signature and not an App Store release.

## Usage

| Action | How |
| --- | --- |
| New note | `+`, ⌘N, or the pin menu |
| Close | `×` or ⌘W. Non-empty text asks for confirmation |
| Keep above windows | Pin button or ⌘P |
| Lock editing | Lock button on the note |
| Color and font size | Color swatches and `A−` / `A+` |
| Settings | ⌘, or the pin menu |
| Quit | ⌘Q or the pin menu |

The pin corner follows the text direction: right for Arabic, left for English.

## Project layout

```text
Package.swift          Swift package
Sources/PinFiyCore     Model and storage, no AppKit
Sources/PinFiyApp      Note windows and the menu bar
Tests/PinFiyCoreTests  XCTest tests
scripts/build-app.sh   Builds PinFiy.app
docs/pinFiy-512.png    512×512 logo
```

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md). Report a security issue privately as described in [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE) © 2026 pinFiy contributors
