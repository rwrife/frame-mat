import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

List<int> _pngDimensions(Uint8List bytes) {
  expect(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
  final data = ByteData.sublistView(bytes);
  return [data.getUint32(16), data.getUint32(20)];
}

void main() {
  test(
    'the frame mat artwork is wired to complete platform icon resources',
    () async {
      expect(_pngDimensions(await File('AppStore/icon.png').readAsBytes()), [
        1024,
        1024,
      ]);

      final catalog =
          jsonDecode(
                await File(
                  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',
                ).readAsString(),
              )
              as Map<String, dynamic>;
      for (final image in catalog['images'] as List<dynamic>) {
        final entry = image as Map<String, dynamic>;
        final logicalSize = (entry['size'] as String)
            .split('x')
            .map(double.parse)
            .toList();
        final scale = double.parse(
          (entry['scale'] as String).replaceAll('x', ''),
        );
        expect(
          _pngDimensions(
            await File(
              'ios/Runner/Assets.xcassets/AppIcon.appiconset/${entry['filename']}',
            ).readAsBytes(),
          ),
          [for (final size in logicalSize) (size * scale).round()],
        );
      }

      const androidSizes = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      };
      for (final entry in androidSizes.entries) {
        expect(
          _pngDimensions(
            await File(
              'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
            ).readAsBytes(),
          ),
          [entry.value, entry.value],
        );
      }
      expect(
        await File('android/app/src/main/AndroidManifest.xml').readAsString(),
        contains('@mipmap/ic_launcher'),
      );

      final windowsResources = await File(
        'windows/runner/resources/app_icon.ico',
      ).readAsBytes();
      final ico = ByteData.sublistView(windowsResources);
      expect(ico.getUint16(0, Endian.little), 0);
      expect(ico.getUint16(2, Endian.little), 1);
      final imageCount = ico.getUint16(4, Endian.little);
      expect(imageCount, greaterThan(0));
      for (var index = 0; index < imageCount; index++) {
        final entry = 6 + index * 16;
        final length = ico.getUint32(entry + 8, Endian.little);
        final offset = ico.getUint32(entry + 12, Endian.little);
        expect(length, greaterThan(0));
        expect(offset + length, lessThanOrEqualTo(windowsResources.length));
      }
      expect(
        await File('windows/runner/Runner.rc').readAsString(),
        contains('resources\\\\app_icon.ico'),
      );
    },
  );
}
