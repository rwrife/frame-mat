# Frame Mat plan

## Scope and architecture
Flutter 3.44.0 / Dart 3.12.0 single codebase; Windows release primary, Android/iOS phone and tablet support enabled. `com.infinityball.framemat` across Android, iOS and planned Windows identity. Keep dimension math in pure Dart (`MatGeometry`): validate finite positive dimensions, opening, borders, board/frame clearance and overlap; units normalized to millimeters. Never quietly round a cut measurement or treat a warning as a measured fit. UI observes immutable calculations. Local draft repository and versioned JSON import/export follow domain logic; PDF worksheet follows tested geometry. No cloud service.

UX strategy A: a small `AdaptiveScaffold`/`AdaptiveButton`/`AdaptiveDialog` seam renders Cupertino iOS/iPadOS, Material 3 Android and Fluent Windows. Platform-native file/print dialogs, back behavior, scrolling and shortcuts. At phone width, form and preview stack; at tablet/desktop widths, resizable two-pane layout with keyboard/mouse/hover support. Font scaling, semantics, focus and high contrast are required.

## Ordered milestones
1. Replace stock demo with domain rules and tests; create minimal adaptive shell, CI on `windows-latest` (`flutter test`, `flutter build windows --release`) plus Linux Docker checks and Android debug APK check. Pin measured toolchain. Verify iOS compile on macOS when runner available.
2. Enter dimensions with unit conversion and fit warnings; preview single mat and then double mat, with accessible platform-specific forms and `TargetPlatform.iOS`, `.android`, `.windows` widget/golden tests.
3. Add local drafts, versioned JSON import/export, invalid-file rejection without overwriting existing drafts and print/PDF cutting worksheet. Confirm backup round-trip on all targets.
4. Review `AppStore/description.txt` against implemented features. Generated `AppStore/icon.png` is already wired to Windows ICO, Android mipmaps and iOS icon set; verify compiled resource and visual legibility, no placeholder icon. Add `.github/workflows/release.yml` triggered by `v*`/manual dispatch, publish zipped portable Windows build to GitHub release. TestFlight and Play submission later.

## Tests and risks
Pure Dart geometry tests for zero/negative/nonfinite dimensions, exact-fit boundaries, overlap and round-trip units; one runnable check must stay with every logic slice. UI widget/golden checks across TargetPlatform.iOS, android and windows and phone/tablet/desktop widths. Integration tests for import validation, backup, PDF measurements. Windows Actions build is release proof; Linux Docker is not Windows/iOS proof. Physical rulers, frame rebates and real cutter tolerances vary: show assumptions, never guarantee fit; request user confirmation before exporting worksheet. Local file permissions and potentially private photo paths require care; import/export are explicit. No automated measurements, image editor, accounts, subscription or cloud sync.

App Store Connect bundle registration blocked by `FAILED bundleId lookup rejected: FORBIDDEN_ERROR.PLA_NOT_ACCEPTED`; owner action documented in README. Secrets `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `ASC_TEAM_ID` are configured as names only and never printed. iOS and Android builds not yet validated.
