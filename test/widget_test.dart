import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frame_mat/main.dart';
import 'package:frame_mat/draft_store.dart';

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

class _MemoryStore extends DraftStore {
  _MemoryStore() : super(Directory('.'));
  List<MatDraft> saved = [];
  @override
  Future<List<MatDraft>> load() async => saved;
  @override
  Future<void> save(List<MatDraft> drafts) async {
    saved = drafts;
  }
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
  for (final platform in [
    TargetPlatform.iOS,
    TargetPlatform.android,
    TargetPlatform.windows,
  ]) {
    testWidgets('$platform shows lower cut and frame rebate warning', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 900);
      try {
        await tester.pumpWidget(FrameMatApp(platform: platform));
        final toggle = find.text('Double mat: off (switch)');
        await tester.ensureVisible(toggle);
        await tester.pumpAndSettle();
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Lower opening: 182.0 × 282.0'),
          findsOneWidget,
        );
        await enterMeasurement(tester, 'Frame aperture width', '280', platform);
        await enterMeasurement(
          tester,
          'Frame aperture height',
          '380',
          platform,
        );
        expect(
          find.text(
            'Frame visible aperture exceeds board; frame may not retain mat.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    });
  }
  for (final platform in [
    TargetPlatform.iOS,
    TargetPlatform.android,
    TargetPlatform.windows,
  ]) {
    testWidgets('$platform saves and switches local draft in UI', (
      tester,
    ) async {
      final store = _MemoryStore();
      try {
        await tester.pumpWidget(FrameMatApp(platform: platform, store: store));
        await tester.pump();
        final nameField = find.descendant(
          of: find.byKey(const ValueKey('Draft name')),
          matching: find.byType(
            platform == TargetPlatform.iOS
                ? CupertinoTextField
                : platform == TargetPlatform.windows
                ? fluent.TextBox
                : TextField,
          ),
        );
        await tester.ensureVisible(nameField);
        await tester.enterText(nameField, 'MyMat');
        await enterMeasurement(tester, 'Artwork width', '150', platform);
        final saveBtn = find.text('Save draft');
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pump();
        expect(find.text('Open MyMat'), findsOneWidget);

        // Edit local field, then re-open saved draft and verify restored value.
        await enterMeasurement(tester, 'Artwork width', '999', platform);
        expect(find.textContaining('999'), findsWidgets);
        await tester.ensureVisible(find.text('Open MyMat'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open MyMat'));
        await tester.pumpAndSettle();
        expect(store.saved.single.values['Artwork width'], '150');
        final artwork = find.descendant(
          of: find.byKey(const ValueKey('Artwork width')),
          matching: find.byType(
            platform == TargetPlatform.iOS
                ? CupertinoTextField
                : platform == TargetPlatform.windows
                ? fluent.TextBox
                : TextField,
          ),
        );
        expect((tester.widget(artwork) as dynamic).controller.text, '150');
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  }
}
