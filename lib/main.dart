import 'dart:math' as math;

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frame_mat/mat_geometry.dart';

void main() => runApp(const FrameMatApp());

class FrameMatApp extends StatelessWidget {
  const FrameMatApp({super.key, this.platform});

  final TargetPlatform? platform;

  @override
  Widget build(BuildContext context) {
    final target = platform ?? defaultTargetPlatform;
    if (target == TargetPlatform.iOS) {
      return CupertinoApp(
        title: 'Frame Mat',
        home: CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Frame Mat'),
          ),
          child: SafeArea(child: Workspace(platform: target)),
        ),
      );
    }
    if (target == TargetPlatform.windows) {
      return fluent.FluentApp(
        title: 'Frame Mat',
        home: fluent.NavigationView(
          pane: fluent.NavigationPane(
            selected: 0,
            items: [
              fluent.PaneItem(
                icon: const fluent.Icon(fluent.FluentIcons.picture),
                title: const Text('Workspace'),
                body: Workspace(platform: target),
              ),
            ],
          ),
        ),
      );
    }
    return MaterialApp(
      title: 'Frame Mat',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueGrey),
      home: Scaffold(
        appBar: AppBar(title: const Text('Frame Mat')),
        body: Workspace(platform: target),
      ),
    );
  }
}

class Workspace extends StatefulWidget {
  const Workspace({super.key, required this.platform});

  final TargetPlatform platform;

  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  static const defaults = <String, String>{
    'Artwork width': '200',
    'Artwork height': '300',
    'Opening width': '190',
    'Opening height': '290',
    'Left border': '40',
    'Right border': '40',
    'Top border': '50',
    'Bottom border': '50',
    'Stock width': '270',
    'Stock height': '390',
    'Frame width': '270',
    'Frame height': '390',
    'Lower reveal left': '4',
    'Lower reveal right': '4',
    'Lower reveal top': '4',
    'Lower reveal bottom': '4',
    'Frame aperture width': '',
    'Frame aperture height': '',
  };

  late final fields = {
    for (final entry in defaults.entries)
      entry.key: TextEditingController(text: entry.value),
  };
  LengthUnit unit = LengthUnit.millimeters;
  bool doubleMat = false;

  Dimensions? get aperture {
    final width = fields['Frame aperture width']!.text.trim();
    final height = fields['Frame aperture height']!.text.trim();
    if (width.isEmpty && height.isEmpty) return null;
    if (width.isEmpty || height.isEmpty) {
      throw const FormatException(
        'Enter both frame aperture dimensions or leave both blank.',
      );
    }
    return Dimensions(
      value('Frame aperture width'),
      value('Frame aperture height'),
    );
  }

  Borders get reveal => Borders(
    value('Lower reveal left'),
    value('Lower reveal right'),
    value('Lower reveal top'),
    value('Lower reveal bottom'),
  );

  @override
  void dispose() {
    for (final controller in fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double value(String name) {
    final raw = fields[name]!.text.trim();
    final number = double.tryParse(raw);
    if (number == null || !number.isFinite || number <= 0) {
      throw FormatException('$name must be a positive, finite number.');
    }
    return number;
  }

  MatPlan get plan => MatPlan(
    unit: unit,
    artwork: Dimensions(value('Artwork width'), value('Artwork height')),
    opening: Dimensions(value('Opening width'), value('Opening height')),
    borders: Borders(
      value('Left border'),
      value('Right border'),
      value('Top border'),
      value('Bottom border'),
    ),
    stock: Dimensions(value('Stock width'), value('Stock height')),
    frame: Dimensions(value('Frame width'), value('Frame height')),
    lowerReveal: doubleMat ? reveal : null,
    frameAperture: aperture,
  );

  void changeUnit() {
    final next = unit == LengthUnit.millimeters
        ? LengthUnit.inches
        : LengthUnit.millimeters;
    // Validate all conversions before changing any field; invalid drafts stay intact.
    final converted = <String, String>{};
    try {
      for (final entry in fields.entries) {
        if (entry.value.text.trim().isNotEmpty) {
          converted[entry.key] = unit
              .convert(value(entry.key), next)
              .toString();
        }
      }
    } on ArgumentError {
      return;
    } on FormatException {
      return;
    }
    setState(() {
      for (final entry in converted.entries) {
        fields[entry.key]!.text = entry.value;
      }
      unit = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    MatPlan? current;
    String? error;
    try {
      current = plan;
    } on FormatException catch (e) {
      error = e.message;
    } on ArgumentError catch (e) {
      error = e.message?.toString() ?? 'Measurements exceed supported range.';
    }

    final form = _Section(
      platform: widget.platform,
      title: 'Measurements',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AdaptiveButton(
            platform: widget.platform,
            onPressed: changeUnit,
            label:
                'Unit: ${unit == LengthUnit.millimeters ? 'mm' : 'in'} (switch)',
          ),
          const SizedBox(height: 12),
          for (final group in [
            'Artwork',
            'Opening',
            'Border',
            'Stock',
            'Frame',
            'Frame aperture',
            'Lower reveal',
          ]) ...[
            if (group == 'Lower reveal')
              _AdaptiveButton(
                platform: widget.platform,
                label: doubleMat
                    ? 'Double mat: on (switch)'
                    : 'Double mat: off (switch)',
                onPressed: () => setState(() => doubleMat = !doubleMat),
              ),
            if (group != 'Lower reveal' || doubleMat) ...[
              Text(group, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              for (final name in defaults.keys.where(
                (key) => group == 'Border'
                    ? key.endsWith('border')
                    : group == 'Frame'
                    ? key == 'Frame width' || key == 'Frame height'
                    : key.startsWith(group),
              ))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AdaptiveField(
                    key: ValueKey(name),
                    platform: widget.platform,
                    label:
                        '$name (${unit == LengthUnit.millimeters ? 'mm' : 'in'})',
                    controller: fields[name]!,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
            ],
          ],
        ],
      ),
    );

    final preview = _Section(
      platform: widget.platform,
      title: 'Preview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (error != null)
            Text(error, key: const Key('measurement-error'))
          else ...[
            Text(
              'Outer cut: ${current!.outer.width} × ${current.outer.height} ${unit == LengthUnit.millimeters ? 'mm' : 'in'}',
              key: const Key('outer-cut'),
            ),
            Text(
              'Opening: ${current.opening.width} × ${current.opening.height} ${unit == LengthUnit.millimeters ? 'mm' : 'in'}',
            ),
            Text(
              'Borders L/R/T/B: ${current.borders.left} / ${current.borders.right} / ${current.borders.top} / ${current.borders.bottom}',
            ),
            if (doubleMat) ...[
              Text(
                'Lower opening: ${current.lowerOpening == null ? 'Not cuttable' : '${current.lowerOpening!.width} × ${current.lowerOpening!.height}'} ${unit == LengthUnit.millimeters ? 'mm' : 'in'}',
              ),
              Text(
                'Lower reveal L/R/T/B: ${current.lowerReveal!.left} / ${current.lowerReveal!.right} / ${current.lowerReveal!.top} / ${current.lowerReveal!.bottom}',
              ),
            ],
            if (current.frameAperture != null)
              Text(
                'Frame visible aperture: ${current.frameAperture!.width} × ${current.frameAperture!.height} ${unit == LengthUnit.millimeters ? 'mm' : 'in'}',
              ),
            Text(
              'Artwork overlap per edge H/V: ${current.effectiveHorizontalOverlap} / ${current.effectiveVerticalOverlap}',
            ),
            if (doubleMat)
              const Text(
                'Lower mat must match upper outer cut; allow for material thickness and independently check alignment.',
              ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1,
              child: Semantics(
                label:
                    'Scaled mat layout. Outer ${current.outer.width} by ${current.outer.height}; upper opening ${current.opening.width} by ${current.opening.height}${current.lowerReveal == null ? '' : '; lower opening ${current.lowerOpening == null ? 'not cuttable' : '${current.lowerOpening!.width} by ${current.lowerOpening!.height}'}'}.',
                image: true,
                child: CustomPaint(
                  key: const Key('mat-preview'),
                  painter: _MatPainter(
                    current,
                    MediaQuery.highContrastOf(context),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              current.warnings.isEmpty
                  ? 'No calculated fit warnings.'
                  : 'Calculated fit warnings:',
              key: const Key('fit-status'),
            ),
            for (final warning in current.warnings) Text(_warningText(warning)),
          ],
          const SizedBox(height: 12),
          const Text(
            'Assumes centered opening and square cuts. Check artwork, frame rebate, board and cutter tolerances with physical measurements before cutting. Calculated fit is not a guarantee.',
          ),
        ],
      ),
    );

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [form, const SizedBox(height: 16), preview],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: form),
                      const SizedBox(width: 24),
                      Expanded(child: preview),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

String _warningText(MatWarning warning) => switch (warning) {
  MatWarning.noHorizontalOverlap =>
    'Opening width leaves no horizontal artwork overlap.',
  MatWarning.noVerticalOverlap =>
    'Opening height leaves no vertical artwork overlap.',
  MatWarning.artworkExtendsBeyondBoardLeft =>
    'Artwork extends beyond left mat edge.',
  MatWarning.artworkExtendsBeyondBoardRight =>
    'Artwork extends beyond right mat edge.',
  MatWarning.artworkExtendsBeyondBoardTop =>
    'Artwork extends beyond top mat edge.',
  MatWarning.artworkExtendsBeyondBoardBottom =>
    'Artwork extends beyond bottom mat edge.',
  MatWarning.boardExceedsStock => 'Outer cut exceeds available stock.',
  MatWarning.boardExceedsFrame => 'Outer cut exceeds frame dimensions.',
  MatWarning.lowerOpeningNonPositive =>
    'Lower opening is zero or negative; reduce lower reveal.',
  MatWarning.frameApertureExceedsBoard =>
    'Frame visible aperture exceeds board; frame may not retain mat.',
  MatWarning.frameObscuresOpening =>
    'Frame visible aperture is smaller than upper opening; frame hides artwork or reveal.',
};

class _AdaptiveField extends StatelessWidget {
  const _AdaptiveField({
    super.key,
    required this.platform,
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final TargetPlatform platform;
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (platform == TargetPlatform.iOS) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          CupertinoTextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            placeholder: label,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.eE+\-]')),
            ],
          ),
        ],
      );
    }
    if (platform == TargetPlatform.windows) {
      return fluent.InfoLabel(
        label: label,
        child: fluent.TextBox(
          controller: controller,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
    }
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _AdaptiveButton extends StatelessWidget {
  const _AdaptiveButton({
    required this.platform,
    required this.label,
    required this.onPressed,
  });

  final TargetPlatform platform;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (platform == TargetPlatform.iOS) {
      return CupertinoButton(onPressed: onPressed, child: Text(label));
    }
    if (platform == TargetPlatform.windows) {
      return fluent.Button(onPressed: onPressed, child: Text(label));
    }
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    required this.platform,
  });

  final String title;
  final Widget child;
  final TargetPlatform platform;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
    if (platform == TargetPlatform.iOS) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
            context,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: content,
      );
    }
    if (platform == TargetPlatform.windows) {
      return fluent.Card(child: content);
    }
    return Card(child: content);
  }
}

class _MatPainter extends CustomPainter {
  const _MatPainter(this.plan, this.highContrast);

  final MatPlan plan;
  final bool highContrast;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = plan.outer;
    final scale =
        math.min(size.width / outer.width, size.height / outer.height) * 0.9;
    final x = (size.width - outer.width * scale) / 2;
    final y = (size.height - outer.height * scale) / 2;
    final board = Rect.fromLTWH(
      x,
      y,
      outer.width * scale,
      outer.height * scale,
    );
    final opening = Rect.fromLTWH(
      x + plan.borders.left * scale,
      y + plan.borders.top * scale,
      plan.opening.width * scale,
      plan.opening.height * scale,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xffffffff),
    );
    canvas.drawRect(
      board,
      Paint()
        ..color = highContrast
            ? const Color(0xff000000)
            : const Color(0xff345a77),
    );
    canvas.drawRect(opening, Paint()..color = const Color(0xffffffff));
    if (plan.lowerReveal != null) {
      final lower = plan.lowerOpening;
      if (lower != null) {
        final inner = Rect.fromLTWH(
          x + plan.lowerOpeningLeft * scale,
          y + plan.lowerOpeningTop * scale,
          lower.width * scale,
          lower.height * scale,
        );
        canvas.drawRect(
          opening,
          Paint()
            ..color = highContrast
                ? const Color(0xff000000)
                : const Color(0xffb57048),
        );
        canvas.drawRect(inner, Paint()..color = const Color(0xffffffff));
        canvas.drawRect(
          inner,
          Paint()
            ..color = const Color(0xff17334c)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
    canvas.drawRect(
      opening,
      Paint()
        ..color = highContrast
            ? const Color(0xff000000)
            : const Color(0xff17334c)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // ponytail: frame rebate remains numerical; visual bezel requires measured rebate on each edge.
  }

  @override
  bool shouldRepaint(covariant _MatPainter oldDelegate) =>
      oldDelegate.plan != plan || oldDelegate.highContrast != highContrast;
}
