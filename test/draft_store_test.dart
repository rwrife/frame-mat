import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frame_mat/draft_store.dart';
import 'package:frame_mat/mat_geometry.dart';

void main() {
  late Directory dir;
  late DraftStore store;
  late MatDraft draft;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('frame-mat-drafts-');
    store = DraftStore(dir);
    draft = MatDraft('Sample', LengthUnit.inches, true, {
      for (final key in MatDraft.fields)
        key: key.startsWith('Frame aperture') ? '' : '1.125',
    });
  });
  tearDown(() async => dir.delete(recursive: true));

  test(
    'save/restart/export/import/delete preserves exact text and options',
    () async {
      await store.save([draft]);
      final restored = (await DraftStore(dir).load()).single;
      expect(restored.unit, LengthUnit.inches);
      expect(restored.doubleMat, isTrue);
      expect(restored.values['Opening width'], '1.125');
      final backup = store.encode([restored]);
      await store.save([]);
      await store.import(backup);
      expect((await store.load()).single.toJson(), draft.toJson());
      await store.save([]);
      expect(await store.load(), isEmpty);
    },
  );

  test(
    'malformed, unsupported, and out-of-range import keep previous data',
    () async {
      await store.save([draft]);
      final original = await File(
        '${dir.path}${Platform.pathSeparator}drafts.json',
      ).readAsBytes();
      final invalid = <List<int>>[
        utf8.encode('{'),
        utf8.encode('{"schemaVersion":2,"drafts":[]}'),
        utf8.encode('not a backup'),
        utf8.encode('{"schemaVersion":1,"drafts":[{},{}]}'),
        utf8.encode('{"schemaVersion":1,"drafts":[],"extra":true}'),
        utf8.encode('{"schemaVersion":1,"drafts":"bad"}'),
        utf8.encode('{"schemaVersion":1,"drafts":[{"name":true}]}'),
        utf8.encode('{"schemaVersion":1,"drafts":['),
      ];
      final bad = jsonDecode(utf8.decode(original)) as Map<String, dynamic>;
      (bad['drafts'] as List).first['values']['Artwork width'] = 'NaN';
      invalid.add(utf8.encode(jsonEncode(bad)));
      invalid.add(List.filled(DraftStore.maxBytes + 1, 32));
      for (final bytes in invalid) {
        await expectLater(store.import(bytes), throwsFormatException);
        expect(
          await File(
            '${dir.path}${Platform.pathSeparator}drafts.json',
          ).readAsBytes(),
          original,
        );
      }
    },
  );

  test('duplicate names and incomplete/aperture input rejected', () async {
    expect(() => store.encode([draft, draft]), throwsFormatException);
    expect(
      () => MatDraft('Bad', draft.unit, true, {
        ...draft.values,
        'Frame aperture width': '2',
      }),
      throwsFormatException,
    );
    expect(
      () => MatDraft(
        'Bad',
        draft.unit,
        true,
        {...draft.values}..remove('Opening width'),
      ),
      throwsFormatException,
    );
  });

  test(
    'interrupted replace recovers saved backup, ignores incomplete temp',
    () async {
      await store.save([draft]);
      final primary = File('${dir.path}${Platform.pathSeparator}drafts.json');
      await primary.rename('${primary.path}.bak');
      await File('${primary.path}.tmp').writeAsString('partial');
      expect((await DraftStore(dir).load()).single.name, 'Sample');
      await store.save([]);
      expect(await store.load(), isEmpty);
      expect(await File('${primary.path}.bak').exists(), isFalse);
    },
  );

  test('corrupt local file is reported, never treated as empty', () async {
    await File(
      '${dir.path}${Platform.pathSeparator}drafts.json',
    ).writeAsString('oops');
    await expectLater(store.load(), throwsFormatException);
  });
}
