import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frame_mat/main.dart';

void main() {
  for (final platform in [
    TargetPlatform.iOS,
    TargetPlatform.android,
    TargetPlatform.windows,
  ]) {
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
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        }
      });
    }
  }
}
