# Campus Personal V5

**English** | [简体中文](docs/README.zh-CN.md) | [Deutsch](docs/README.de.md)

A personal Android fork of [TUM-Dev/campus_flutter](https://github.com/TUM-Dev/campus_flutter), restoring calendar-driven lecture details through the public TUMonline course website endpoint.

Version **5.3.1+5** · Android **10+** · package `de.tum.in.tumcampus.personal` · app name **Campus Personal**.

## What changed

- Read real course titles, semester, teaching team, syllabus, objectives and other available details from TUMonline's public course endpoint.
- Recognize the calendar link format `lv.detail?cLvNr=...`, which earlier personal builds missed.
- Keep loading, success and error states separate. Failed requests show an error and retry; missing fields are omitted.
- Link meeting rooms to [NavigaTUM](https://nav.tum.de/) using their full room codes.
- Use the supplied blue launcher artwork and a separate Android package alongside the original app.

## Analysis: choose a language

[English](docs/lecture-data.en.md) · [简体中文](docs/lecture-data.zh-CN.md) · [Deutsch](docs/lecture-data.de.md)

The analysis distinguishes the original app's legacy API outage from the early personal fork's `cLvNr` parsing regression. It explains the current request flow, XML field mapping, UI organization and verification scope.

## Build

The V5 build used Flutter **3.47.7**, Dart **3.13.5**, JDK **21**, Android SDK **36**, build-tools **35.0.0**, and NDK **28.2.13676358**.

```sh
flutter pub get
flutter test
```

PowerShell:

```powershell
$env:CAMPUS_PERSONAL_BUILD='true'
flutter build apk --release --target lib/main.dart --dart-define=PERSONAL_BUILD=true
```

Bash:

```sh
CAMPUS_PERSONAL_BUILD=true flutter build apk --release --target lib/main.dart --dart-define=PERSONAL_BUILD=true
```

Both personal-build switches are required. The APK is generated at `build/app/outputs/flutter-apk/app-release.apk`. Local Android debug signing is the default unless a release keystore is configured. Keep the same signing key for compatible updates; the previously delivered private signing key is not included here.

For the complete build and Android integration-test commands, see [README_PERSONAL.md](README_PERSONAL.md). The manual [personal Android build workflow](.github/workflows/build_personal.yml) is also included; this repository upload does not run it.

## Verified V5 behavior

On **2026-10-20**: 141 Flutter tests passed; relevant static analysis passed; two course scenarios fetched live data on an Android 15 emulator and scrolled to their teaching contents. The release APK also passed signature, overwrite-installation and cold-start checks. These are recorded V5 results, not a fresh server-status check on the upload date.

[Android screenshots](docs/images/) · [Validation records](docs/validation/) · [Detailed scope](docs/lecture-data.en.md#verification-and-scope)

Private enrollment-list access still uses the separate legacy service. Its permissions-screen warning may remain even when calendar-based public course details work.

## Source and license

Application source, assets, test fixtures and build scripts originate from the delivered V5 snapshot, based on upstream commit `9b10141dc53b9552945245a9a978a0b8405a7153`. The original [GPL-3.0 license](LICENSE) and [upstream README](docs/upstream-README.md) are retained. This is an unofficial personal fork.

Repository documentation and language navigation were added on **2026-10-21**. See [source provenance](docs/source-provenance.md) for snapshot hashes and the publication-only differences. APKs, SDKs, caches and signing keys are not stored in Git.
