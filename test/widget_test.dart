import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frame_mat/main.dart';

// Find an input in the scrollable phone form without assuming it is visible.
Future<void> enterMeasurement(
  WidgetTester tester,
  String name,
  String text,
  TargetPlatform platform,
) async {
  final field = find.descendant(
    of: find.byKey(ValueKey(name)),
    matching: find.byType(
      platform == TargetPlatform.iOS
          ? CupertinoTextField
          : platform == TargetPlatform.windows
          ? fluent.TextBox
          : TextField,
    ),
  );
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

void main() {
  for (final platform in [
    TargetPlatform.iOS,
    TargetPlatform.android,
    TargetPlatform.windows,
  ]) {
    testWidgets('$platform supports enlarged text and keyboard focus', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 900);
      tester.view.platformDispatcher.textScaleFactorTestValue = 3.3;
      try {
        await tester.pumpWidget(FrameMatApp(platform: platform));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final field = find.descendant(
          of: find.byKey(const ValueKey('Artwork width')),
          matching: find.byType(
            platform == TargetPlatform.iOS
                ? CupertinoTextField
                : platform == TargetPlatform.windows
                ? fluent.TextBox
                : TextField,
          ),
        );
        await tester.ensureVisible(field);
        await tester.tap(field);
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isTrue);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.view.platformDispatcher.clearTextScaleFactorTestValue();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    });
    for (final width in [390.0, 900.0, 1440.0]) {
      testWidgets('$platform at ${width.toInt()} px', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        try {
          await tester.pumpWidget(FrameMatApp(platform: platform));
          expect(find.text('Measurements'), findsOneWidget);
          expect(find.text('Preview'), findsOneWidget);
          expect(find.text('Flutter Demo'), findsNothing);
          expect(tester.takeException(), isNull);
          // Linux-generated pixels differ from Windows font rendering.
          if (Platform.isLinux) {
            await expectLater(
              find.byType(Workspace),
              matchesGoldenFile(
                'goldens/${platform.name}-${width.toInt()}.png',
              ),
            );
          }
          if (platform == TargetPlatform.iOS) {
            expect(find.byType(CupertinoApp), findsOneWidget);
            expect(find.byType(MaterialApp), findsNothing);
          } else if (platform == TargetPlatform.android) {
            expect(find.byType(MaterialApp), findsOneWidget);
            expect(find.byType(CupertinoApp), findsNothing);
          } else {
            expect(find.byType(fluent.FluentApp), findsOneWidget);
            expect(find.byType(fluent.NavigationView), findsOneWidget);
          }
          if (width == 900) {
            await enterMeasurement(
              tester,
              'Opening width',
              '190.125',
              platform,
            );
            expect(find.textContaining('270.125 × 390'), findsOneWidget);
            expect(
              find.text('Outer cut exceeds available stock.'),
              findsOneWidget,
            );
            await enterMeasurement(tester, 'Opening width', 'bad', platform);
            expect(find.byKey(const Key('measurement-error')), findsOneWidget);
            expect(find.byKey(const Key('mat-preview')), findsNothing);
            await enterMeasurement(tester, 'Opening width', '190', platform);
            expect(find.text('No calculated fit warnings.'), findsOneWidget);
            tester.testTextInput.hide();
            await tester.ensureVisible(find.text('Unit: mm (switch)'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Unit: mm (switch)'));
            await tester.pumpAndSettle();
            expect(find.textContaining('Unit: in (switch)'), findsOneWidget);
            expect(find.textContaining('Outer cut: 10.'), findsOneWidget);
            await tester.tap(find.text('Unit: in (switch)'));
            await tester.pumpAndSettle();
            expect(find.textContaining('Outer cut: 270'), findsOneWidget);
          }
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        }
      });
    }
  }
}
