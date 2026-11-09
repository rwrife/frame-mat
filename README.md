# Frame Mat

Offline photo mat-cut planner: enter artwork, frame and border dimensions, check fit, and export cut measurements on phone, tablet and Windows.

## Why and who
Home framers and craft clubs often discover too late that a mount-board opening covers artwork or that proposed borders cannot fit an existing frame. Frame Mat turns measured dimensions into a reproducible cutting worksheet. Unlike general photo-editing suites, it does not edit images or sell supplies.

## Intended workflow
1. Measure artwork width/height and desired visible margin in millimeters; record frame aperture and board dimensions.
2. Enter top, side and bottom mat borders. Preview visible opening and outer board at scale; warn on nonpositive opening, insufficient overlap or board larger than frame aperture.
3. Save a draft locally; print or export a dimensioned worksheet and backup JSON before cutting. Verify physical measurements independently; app is not a cutting machine or safety-rated tool.

## MVP, not yet built
- Single and double mat dimensions, explicit units and deterministic geometry with tested edge cases.
- Draft list and a dimensioned, responsive preview; touch and keyboard/mouse input on phones, tablets and Windows.
- Local save/load and user-owned JSON backup plus print-friendly PDF worksheet.
- Readable high contrast, scalable text, screen-reader labels and full Windows keyboard navigation.

Non-goals: automatic camera measurement, commerce, image editing, cloud accounts, irreversible cutting instructions, multi-user sync.

## Platform and privacy
Flutter single codebase for Windows (primary release), Android and iOS, including Android tablets and iPad. `com.infinityball.framemat` is Android application ID, iOS bundle ID and planned Windows identity. UX strategy A: Cupertino on iOS, Material 3 on Android and Fluent on Windows, behind a thin adaptive widget seam; never ship starter Material UI on iOS or phone UI on Windows. Local storage only; photo/file permission only on explicit import/export. No analytics, account, network access or medical claims. No secret values in repo. Store copy: `AppStore/description.txt`.

Generated `AppStore/icon.png` (OpenAI Images `gpt-image-2.5-flare`) is wired into Windows ICO, Android mipmaps and iOS AppIcon rasters; source artwork is outside repo under `~/media/frame-mat/images/20261109T051040Z_openai_d57c46.png`. Icon appearance and compiled resources still need platform checks.

## Status and build
Flutter platform skeleton and stock counter test only. Geometry, adaptive UI, persistence, release CI and actual application functionality remain backlog. Flutter scaffold image measured at 3.44.0, Dart 3.12.0; exact revision is recorded in `toolchain.json`. For local development: `flutter pub get && flutter test`; `flutter run -d windows` on Windows, or `flutter run -d android` / `flutter run -d ios` on corresponding SDK hosts. Headless Linux checks use Docker; Windows and iOS builds not verified here.

MVP release: `.github/workflows/release.yml` on `v*` tags or manual dispatch builds zipped Windows app on `windows-latest` and attaches GitHub release asset. Android debug APK compile gate and iOS compile gate planned; TestFlight via repository secret **names** `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `ASC_TEAM_ID`, and Play submission are later opt-in milestones.

## Manual setup required
`com.infinityball.framemat` App Store Connect registration failed: `FAILED bundleId lookup rejected: FORBIDDEN_ERROR.PLA_NOT_ACCEPTED`. Apple Developer account owner must accept current Program License Agreement before retry. Bundle ID is not claimed registered; four ASC repository secrets were configured by name.
