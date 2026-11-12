import 'dart:convert';
import 'dart:io';

import 'package:frame_mat/mat_geometry.dart';

/// Exact text is retained: no conversion or cut-measurement rounding on save.
class MatDraft {
  MatDraft(this.name, this.unit, this.doubleMat, Map<String, String> values)
    : values = Map.unmodifiable(values) {
    if (name.trim() != name ||
        name.isEmpty ||
        name.length > 80 ||
        name.runes.any((r) => r < 32 || r == 127)) {
      throw const FormatException(
        'Draft name must contain 1–80 printable characters.',
      );
    }
    if (values.keys.toSet().length != fields.length ||
        !values.keys.toSet().containsAll(fields)) {
      throw const FormatException('Draft measurements are incomplete.');
    }
    double read(String key) {
      final value = double.tryParse(values[key]!.trim());
      if (value == null || !value.isFinite || value <= 0) {
        throw FormatException('$key must be positive and finite.');
      }
      return value;
    }

    final apertureWidth = values['Frame aperture width']!.trim();
    final apertureHeight = values['Frame aperture height']!.trim();
    if (apertureWidth.isEmpty != apertureHeight.isEmpty) {
      throw const FormatException(
        'Enter both frame aperture dimensions or leave both blank.',
      );
    }
    final plan = MatPlan(
      unit: unit,
      artwork: Dimensions(read('Artwork width'), read('Artwork height')),
      opening: Dimensions(read('Opening width'), read('Opening height')),
      borders: Borders(
        read('Left border'),
        read('Right border'),
        read('Top border'),
        read('Bottom border'),
      ),
      stock: Dimensions(read('Stock width'), read('Stock height')),
      frame: Dimensions(read('Frame width'), read('Frame height')),
      lowerReveal: doubleMat
          ? Borders(
              read('Lower reveal left'),
              read('Lower reveal right'),
              read('Lower reveal top'),
              read('Lower reveal bottom'),
            )
          : null,
      frameAperture: apertureWidth.isEmpty
          ? null
          : Dimensions(
              read('Frame aperture width'),
              read('Frame aperture height'),
            ),
    );
    // Validate hidden fields too; toggling options must never reveal corrupt data.
    for (final key in fields) {
      if (!key.startsWith('Frame aperture') || apertureWidth.isNotEmpty) {
        read(key);
      }
    }
    plan.outer; // Checked arithmetic, including overflow.
  }

  static const fields = <String>{
    'Artwork width',
    'Artwork height',
    'Opening width',
    'Opening height',
    'Left border',
    'Right border',
    'Top border',
    'Bottom border',
    'Stock width',
    'Stock height',
    'Frame width',
    'Frame height',
    'Lower reveal left',
    'Lower reveal right',
    'Lower reveal top',
    'Lower reveal bottom',
    'Frame aperture width',
    'Frame aperture height',
  };

  final String name;
  final LengthUnit unit;
  final bool doubleMat;
  final Map<String, String> values;

  Map<String, Object> toJson() => {
    'name': name,
    'unit': unit.name,
    'doubleMat': doubleMat,
    'values': values,
  };

  factory MatDraft.fromJson(Object? source) {
    if (source is! Map<String, dynamic> ||
        source.keys.toSet().difference({
          'name',
          'unit',
          'doubleMat',
          'values',
        }).isNotEmpty ||
        source.length != 4 ||
        source['name'] is! String ||
        source['unit'] is! String ||
        source['doubleMat'] is! bool ||
        source['values'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid draft schema.');
    }
    final raw = source['values'] as Map<String, dynamic>;
    if (raw.values.any((value) => value is! String)) {
      throw const FormatException('Invalid measurement value.');
    }
    final unit = LengthUnit.values.where(
      (value) => value.name == source['unit'],
    );
    if (unit.length != 1) {
      throw const FormatException('Unsupported unit.');
    }
    return MatDraft(
      source['name'] as String,
      unit.single,
      source['doubleMat'] as bool,
      raw.map((key, value) => MapEntry(key, value as String)),
    );
  }
}

class DraftStore {
  DraftStore(this.directory);

  final Directory directory;
  File get _file =>
      File('${directory.path}${Platform.pathSeparator}drafts.json');
  static const maxBytes = 1024 * 1024;
  static const maxDrafts = 100;

  List<MatDraft> parse(List<int> bytes) {
    if (bytes.length > maxBytes) {
      throw const FormatException('Backup exceeds 1 MiB.');
    }
    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes, allowMalformed: false));
    } on FormatException {
      throw const FormatException('Invalid JSON backup.');
    }
    if (decoded is! Map<String, dynamic> ||
        decoded.length != 2 ||
        decoded['schemaVersion'] != 1 ||
        decoded['drafts'] is! List) {
      throw const FormatException('Unsupported backup schema.');
    }
    final raw = decoded['drafts'] as List;
    if (raw.length > maxDrafts) {
      throw const FormatException('Too many drafts.');
    }
    final drafts = raw.map(MatDraft.fromJson).toList();
    if (drafts.map((d) => d.name).toSet().length != drafts.length) {
      throw const FormatException('Duplicate draft names.');
    }
    return drafts;
  }

  List<int> encode(List<MatDraft> drafts) {
    if (drafts.length > maxDrafts ||
        drafts.map((d) => d.name).toSet().length != drafts.length) {
      throw const FormatException('Too many drafts or duplicate names.');
    }
    final bytes = utf8.encode(
      jsonEncode({
        'schemaVersion': 1,
        'drafts': drafts.map((d) => d.toJson()).toList(),
      }),
    );
    if (bytes.length > maxBytes) {
      throw const FormatException('Backup exceeds 1 MiB.');
    }
    return bytes;
  }

  Future<List<MatDraft>> load() async {
    final backup = File('${_file.path}.bak');
    final current = await _file.exists() ? _file : backup;
    if (!await current.exists()) {
      return [];
    }
    return parse(
      await current.readAsBytes(),
    ); // Corruption never silently resets drafts.
  }

  Future<void> save(List<MatDraft> drafts) async {
    final bytes = encode(drafts);
    await directory.create(recursive: true);
    final tmp = File('${_file.path}.tmp');
    final backup = File('${_file.path}.bak');
    try {
      await tmp.writeAsBytes(bytes, flush: true);
      // Keep old snapshot while replacing on Windows, where rename over a
      // destination may fail. Crash recovery loads .bak if primary is absent.
      if (await _file.exists()) {
        if (await backup.exists()) {
          // Both files exist after previous crash: primary remains authoritative.
          parse(await _file.readAsBytes());
          await backup.delete();
        }
        await _file.rename(backup.path);
      } else if (await backup.exists()) {
        // Interrupted replacement: preserve old snapshot if this save fails.
        parse(await backup.readAsBytes());
      }
      await tmp.rename(_file.path);
      if (await backup.exists()) {
        await backup.delete();
      }
    } catch (_) {
      if (!await _file.exists() && await backup.exists()) {
        await backup.rename(_file.path);
      }
      rethrow;
    } finally {
      if (await tmp.exists()) {
        await tmp.delete();
      }
    }
  }

  Future<void> import(List<int> bytes) async => save(parse(bytes));
}
