import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../theme_presets.dart';

Future<TerminalThemePreset?> showTerminalThemeGallery(
  BuildContext context, {
  required List<TerminalThemePreset> presets,
  String? selectedPresetId,
}) => showMacosSheet<TerminalThemePreset>(
  context: context,
  barrierDismissible: true,
  builder: (_) => Center(
    child: MacosSheet(
      insetPadding: EdgeInsets.zero,
      child: _TerminalThemeGallery(
        presets: presets,
        selectedPresetId: selectedPresetId,
      ),
    ),
  ),
);

class _TerminalThemeGallery extends StatefulWidget {
  const _TerminalThemeGallery({
    required this.presets,
    required this.selectedPresetId,
  });

  final List<TerminalThemePreset> presets;
  final String? selectedPresetId;

  @override
  State<_TerminalThemeGallery> createState() => _TerminalThemeGalleryState();
}

class _TerminalThemeGalleryState extends State<_TerminalThemeGallery> {
  late final TextEditingController _search;
  var _query = '';

  @override
  void initState() {
    super.initState();
    _search = TextEditingController();
    _search.addListener(() => setState(() => _query = _search.text.trim()));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    final query = _query.toLowerCase();
    final filtered = widget.presets
        .where(
          (preset) =>
              query.isEmpty ||
              preset.name.toLowerCase().contains(query) ||
              (preset.author?.toLowerCase().contains(query) ?? false),
        )
        .toList(growable: false);
    return SizedBox(
      width: 780,
      height: 620,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Terminal themes', style: theme.typography.title2),
            const SizedBox(height: 12),
            MacosTextField(
              controller: _search,
              placeholder: 'Search themes or authors',
              prefix: const Icon(Icons.search, size: 16),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 235,
                  mainAxisExtent: 116,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final preset = filtered[index];
                  return _ThemePresetCard(
                    preset: preset,
                    selected: preset.id == widget.selectedPresetId,
                    onTap: () => Navigator.pop(context, preset),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${filtered.length} themes',
              style: theme.typography.caption1,
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemePresetCard extends StatelessWidget {
  const _ThemePresetCard({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final TerminalThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = [
      preset.theme.black,
      preset.theme.red,
      preset.theme.green,
      preset.theme.yellow,
      preset.theme.blue,
      preset.theme.magenta,
      preset.theme.cyan,
      preset.theme.white,
    ];
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: preset.theme.background,
            border: Border.all(
              color: selected
                  ? MacosTheme.of(context).primaryColor
                  : MacosTheme.of(context).dividerColor,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                preset.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: preset.theme.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final color in colors)
                    Expanded(child: Container(height: 12, color: color)),
                ],
              ),
              const Spacer(),
              Text(
                preset.author ?? preset.variant ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: preset.theme.foreground.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
