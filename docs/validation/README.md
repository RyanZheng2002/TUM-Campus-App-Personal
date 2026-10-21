# V5 validation records

These records were produced on **2026-10-20** and copied for the **2026-10-21** source publication. They do not represent a new test run on the publication date.

| Record | Meaning |
| --- | --- |
| [flutter-tests.txt](flutter-tests.txt) | 141 Flutter tests passed |
| [static-analysis.txt](static-analysis.txt) | Relevant source and tests: no issues found |
| [link-parsing-before-after.jsonl](link-parsing-before-after.jsonl) | V4 returned null for calendar cLvNr; V5 returned the correct IDs |
| [public-course-probe.jsonl](public-course-probe.jsonl) | Production adapter retrieved both public course responses |
| [android-integration.txt](android-integration.txt) | Two actual Android live-network course scenarios passed |
| [android-release-cold-start.txt](android-release-cold-start.txt) | Normal release entry point: cold launch succeeded |
| [apk-signature.txt](apk-signature.txt) | APK v2 signature and previously delivered update certificate |
| [v5-source-manifest.sha256](v5-source-manifest.sha256) | Original delivered snapshot's 649 file hashes |

The Android log's `+4` includes suite setup and teardown; it represents **two course scenarios**, not four courses. Meeting metadata was constructed for testing, while course details were fetched live through the production HTTP client without injected responses or a personal token. The normal release APK separately passed overwrite installation and cold start. No physical user phone or private account authorization was tested by these emulator checks.

The [screenshots](../images/) show the actual native Android course views, including scrolled teaching contents. For analysis and field provenance, choose [English](../lecture-data.en.md), [简体中文](../lecture-data.zh-CN.md), or [Deutsch](../lecture-data.de.md).
