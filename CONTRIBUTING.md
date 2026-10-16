# المساهمة

قضايا GitHub وطلبات السحب بالعربية أو الإنجليزية مرحّب بها. ابنِ المشروع بـ `swift test` ثم `./scripts/build-app.sh`. لا تُدخل ملفات `.build` أو `PinFiy.app` أو ملاحظاتك الشخصية.

# Contributing

Issues and pull requests are welcome in Arabic or English.

## Setup

```bash
swift test
./scripts/build-app.sh
open PinFiy.app
```

Requirements are macOS 13 or later and Swift 5.9 or later.

## Pull requests

1. Open an issue for a behavior change before a large pull request.
2. Keep `PinFiyCore` free of AppKit so the unit tests stay headless.
3. Add or update an XCTest when you change storage, colors, direction, pin policy, font size, or closing rules.
4. Run `swift test` and make sure it passes.
5. Do not commit `.build/`, `PinFiy.app/`, or files from `~/Library/Application Support/pinFiy`.
6. Do not add a network client, an account system, or cloud sync.

## Out of scope

Cloud sync, accounts, images inside notes, checklists, notifications, hiding the app from the menu bar, and App Store distribution.

## Code of conduct

This project uses the [Contributor Covenant](CODE_OF_CONDUCT.md).
