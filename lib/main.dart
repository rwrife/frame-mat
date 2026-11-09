import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
          child: SafeArea(child: _Workspace(platform: target)),
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
                body: _Workspace(platform: target),
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
        body: _Workspace(platform: target),
      ),
    );
  }
}

class _Workspace extends StatelessWidget {
  const _Workspace({required this.platform});

  final TargetPlatform platform;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    final sections = [
      _Section(
        title: 'Measurements',
        detail: 'Enter artwork, opening, frame and board dimensions.',
        platform: platform,
      ),
      _Section(
        title: 'Preview',
        detail: 'Check fit and borders before cutting.',
        platform: platform,
      ),
    ];
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      sections[0],
                      const SizedBox(height: 16),
                      sections[1],
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: sections[0]),
                      const SizedBox(width: 24),
                      Expanded(child: sections[1]),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.detail,
    required this.platform,
  });

  final String title;
  final String detail;
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
          Text(detail),
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
