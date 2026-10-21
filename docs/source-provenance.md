# V5 source provenance

Published: **2026-10-21**. V5 verification date: **2026-10-20**.

## Baseline and delivered snapshot

- Upstream: [TUM-Dev/campus_flutter](https://github.com/TUM-Dev/campus_flutter).
- Upstream baseline commit: [`9b10141dc53b9552945245a9a978a0b8405a7153`](https://github.com/TUM-Dev/campus_flutter/commit/9b10141dc53b9552945245a9a978a0b8405a7153).
- Personal version: `5.3.1+5` (Android version code 5).
- Delivered source archive: `campus-personal-v5-source.zip`, **649 files**.
- Archive SHA-256: `493cd81f9683cdc32fc3d36b15e5fe764382936c9038b829dee3694b933cb51e`.
- Previously delivered APK SHA-256: `651389504fc7ad00b050a2e607f6c3d0b40359f057cc6340c13a6f0beb5ee5c8`.

The repository imports the unpacked V5 source snapshot. Application code, test code, assets, dependency lockfile and build scripts are unchanged from that snapshot. The [original-file manifest](validation/v5-source-manifest.sha256) records the per-file hashes of the delivered archive.

## Repository-only preparation

1. Replace the root README with an English-first personal-fork introduction and language navigation; preserve the previous README as `docs/upstream-README.md`.
2. Add Chinese and German introductions, three language versions of the analysis, Android screenshots, and validation evidence.
3. Extend `.gitignore` for local APKs, app bundles, signing keys, local SDK properties and generated output folders.
4. Retain the personal Android workflow at `.github/workflows/build_personal.yml`, with manual triggering only. Archive the original `deploy_beta.yml`, `deploy_web.yml` and `lint_test_build.yml` under `docs/upstream-workflows/`; these upstream deployment/CI examples are preserved as files, not activated for this personal repository.

The root `.gitignore` intentionally differs from its source-manifest hash. The original README and the three archived workflows are verified at their new paths. All other snapshot files match their original bytes.

## Included evidence

[Validation index](validation/README.md) documents test counts, Android live-network scenarios, release checks and the distinction between synthetic calendar meeting metadata and real course responses. Absolute workstation paths in copied logs are replaced with `<workspace>`.

The Git repository contains no APK, local SDK, emulator image, build cache or private signing key. The existing V5 APK was not rebuilt for this documentation/source upload. Rebuilding with a different signing key will not produce an update compatible with the previously delivered signed APK.

Original copyright notices and [GPL-3.0](../LICENSE) remain in place. The previously included Firebase client configuration comes from the upstream source; personal builds disable upstream Firebase initialization. No personal TUM token or user authorization data was added.

Git may normalize line endings when storing text files. The per-file manifest describes the original archive bytes; application logic is unchanged. Existing formatting/whitespace in the imported V5 source and archived upstream documents is retained, while newly written documentation is checked separately.
