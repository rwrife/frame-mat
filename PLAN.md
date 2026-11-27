# Frame Mat plan

## Scope and architecture
Flutter 3.44.0 / Dart 3.12.0 single codebase; Windows release primary, Android/iOS phone and tablet support enabled. `com.infinityball.framemat` across Android, iOS and planned Windows identity. Keep dimension math in pure Dart (`MatGeometry`): validate finite positive dimensions, opening, borders, board/frame clearance and overlap; units normalized to millimeters. Never quietly round a cut measurement or treat a warning as a measured fit. UI observes immutable calculations. Local draft repository and versioned JSON import/export follow domain logic; PDF worksheet follows tested geometry. No cloud service.

UX strategy A: a small `AdaptiveScaffold`/`AdaptiveButton`/`AdaptiveDialog` seam renders Cupertino iOS/iPadOS, Material 3 Android and Fluent Windows. Platform-native file/print dialogs, back behavior, scrolling and shortcuts. At phone width, form and preview stack; at tablet/desktop widths, resizable two-pane layout with keyboard/mouse/hover support. Font scaling, semantics, focus and high contrast are required.

## Delivered milestones
1. Replaced the stock demo with tested mat geometry and adaptive shell. CI pins the toolchain and builds Windows, Android and iOS simulator targets.
2. Added unit conversion, geometry diagnostics, double-mat input and a responsive, accessible preview.
3. Added local drafts, validated versioned JSON backup import/export and recovery-safe writes.
4. Added a dimensioned PDF worksheet, reviewed store copy and verified the framed-mat icon assets. The Windows tag/manual release workflow packages and verifies a portable release asset.

## Tests and risks
Pure Dart geometry tests for zero/negative/nonfinite dimensions, exact-fit boundaries, overlap and round-trip units; one runnable check must stay with every logic slice. UI widget/golden checks across TargetPlatform.iOS, android and windows and phone/tablet/desktop widths. Integration tests for import validation, backup, PDF measurements. Windows Actions build is release proof; Linux Docker is not Windows/iOS proof. Physical rulers, frame rebates and real cutter tolerances vary: show assumptions, never guarantee fit; request user confirmation before exporting worksheet. Local file permissions and potentially private photo paths require care; import/export are explicit. No automated measurements, image editor, accounts, subscription or cloud sync.

App Store Connect bundle registration previously failed with `FORBIDDEN_ERROR.PLA_NOT_ACCEPTED`; Apple Developer account owner must accept the current Program License Agreement before retry. TestFlight and Play submissions are out of MVP scope.
