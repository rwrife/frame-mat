# Frame Mat

Offline photo mat-cut planner: enter artwork, frame and border dimensions, check fit, and export cut measurements on phone, tablet and Windows.

## Why and who
Home framers and craft clubs often discover too late that a mount-board opening covers artwork or that proposed borders cannot fit an existing frame. Frame Mat turns measured dimensions into a reproducible cutting worksheet. Unlike general photo-editing suites, it does not edit images or sell supplies.

## Intended workflow
1. Measure artwork width/height and desired visible margin in millimeters; record frame aperture and board dimensions.
2. Enter top, side and bottom mat borders. Preview visible opening and outer board at scale; warn on nonpositive opening, insufficient overlap or board larger than frame aperture.
3. Save a draft locally; export a dimensioned PDF worksheet and backup JSON before cutting. Verify physical measurements independently; the app is not a cutting machine or safety-rated tool.

## Current features
- Single- and double-mat measurements with explicit units, edge overlap, frame-aperture and stock-fit diagnostics.
- Responsive preview and adaptive iOS Cupertino, Android Material 3 and Windows Fluent interfaces.
- Local named drafts and versioned JSON backup import/export, with validation and crash-recovery for saved drafts.
- One-page PDF cutting worksheet with exact entered measurements, optional double-mat details, fit warnings and physical-measurement disclaimer. Its diagram is illustrative, not a 1:1 template.
- Scalable text, screen-reader semantics, keyboard focus and high-contrast preview support.

Non-goals: automatic camera measurement, commerce, image editing, cloud accounts, irreversible cutting instructions, multi-user sync.

## Local drafts and backups
Save named drafts on this device, reopen them after restarting, or delete them. Replacing a saved draft, opening a draft over current measurements, deleting a draft, and importing a backup require confirmation. Export a versioned JSON backup to transfer drafts without cloud services. Import validates the complete backup before replacing local drafts; invalid input leaves saved drafts unchanged. Interrupted local writes retain a recoverable previous snapshot.

## Platform and privacy
The minimum supported iOS version is 14.0, required by the native file picker used for JSON and PDF export.

Flutter single codebase for Windows (primary release), Android and iOS, including Android tablets and iPad. `com.infinityball.framemat` is Android application ID, iOS bundle ID and planned Windows identity. UX strategy A: Cupertino on iOS, Material 3 on Android and Fluent on Windows, behind a thin adaptive widget seam; never ship starter Material UI on iOS or phone UI on Windows. Local storage only; photo/file permission only on explicit import/export. No analytics, account, network access or medical claims. No secret values in repo. Store copy: `AppStore/description.txt`.

The generated square Frame Mat artwork in `AppStore/icon.png` is used by the Windows ICO, Android launcher mipmaps and iOS AppIcon asset catalog. The art shows a framed mat with measurement marks; it is not a placeholder. Source artwork is maintained outside this repository.

## Status and build
Flutter 3.44.0 / Dart 3.12.0 is pinned in `toolchain.json` and CI; use `flutter pub get --enforce-lockfile && flutter analyze && flutter test` locally. The latest main-branch CI run (16 November 2026) passed Linux tests, Windows release build, Android debug APK and unsigned iOS simulator build. The CI jobs also compile each platform's configured app icon resources.

`.github/workflows/release.yml` builds a portable Windows ZIP on `v*` tags or for a manually selected existing tag, publishes it to that GitHub release, then verifies the asset URL. Android debug APK and iOS simulator compile gates remain in CI. TestFlight and Play submission are not part of this release workflow.

## Manual setup required
`com.infinityball.framemat` App Store Connect registration previously failed with `FORBIDDEN_ERROR.PLA_NOT_ACCEPTED`. Apple Developer account owner must accept the current Program License Agreement before store registration can be retried. No TestFlight or Play submission is performed.
