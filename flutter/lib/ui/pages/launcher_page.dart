import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../terminal_appearance.dart';
import '../components/terminal_theme_gallery.dart';
import 'profile_home_page.dart';

class LauncherPage extends StatefulWidget {
  const LauncherPage({super.key, this.onOpenWorkspace});

  final ValueChanged<String>? onOpenWorkspace;

  @override
  State<LauncherPage> createState() => _LauncherPageState();
}

class _LauncherPageState extends State<LauncherPage> {
  var _selectedIndex = 0;

  static const _navigationBackground = Color.fromRGBO(43, 43, 43, 1);
  static const _contentBackground = Color.fromRGBO(18, 19, 20, 1);

  @override
  Widget build(BuildContext context) {
    return MacosWindow(
      disableWallpaperTinting: true,
      child: MacosScaffold(
        backgroundColor: _contentBackground,
        children: [
          ContentArea(
            builder: (context, scrollController) => Row(
              children: [
                SizedBox(
                  width: 220,
                  child: ColoredBox(
                    color: _navigationBackground,
                    child: SidebarItems(
                      scrollController: scrollController,
                      currentIndex: _selectedIndex,
                      onChanged: (index) =>
                          setState(() => _selectedIndex = index),
                      items: const [
                        SidebarItem(
                          leading: Icon(Icons.workspaces_outlined),
                          label: Text('Workspace Manager'),
                        ),
                        SidebarItem(
                          leading: Icon(Icons.settings_outlined),
                          label: Text('Settings'),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    color: _contentBackground,
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: [
                        ProfileHomePage(
                          onOpenWorkspace: widget.onOpenWorkspace,
                        ),
                        const _SettingsPage(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
        children: [
          Text('Settings', style: MacosTheme.of(context).typography.title2),
          const SizedBox(height: 24),
          Text('Appearance', style: MacosTheme.of(context).typography.headline),
          const SizedBox(height: 12),
          _GlobalThemeSetting(appState: appState),
          _GlobalFontSetting(appState: appState),
          const _SettingRow(
            title: 'Theme',
            value: 'Dark',
            icon: Icons.dark_mode_outlined,
          ),
        ],
      ),
    );
  }
}

class _GlobalFontSetting extends StatelessWidget {
  const _GlobalFontSetting({required this.appState});

  final AppState appState;

  Future<void> _edit(BuildContext context) async {
    final family = TextEditingController(
      text: appState.globalAppearance.fontFamily,
    );
    final size = TextEditingController(
      text: appState.globalAppearance.fontSize.toString(),
    );
    final result = await showMacosSheet<TerminalAppearanceProfile>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _FontSettingsSheet(
        family: family,
        size: size,
        appearance: appState.globalAppearance,
      ),
    );
    family.dispose();
    size.dispose();
    if (result != null) await appState.updateGlobalAppearance(result);
  }

  @override
  Widget build(BuildContext context) => _SettingRow(
    title: 'Terminal font',
    value:
        '${appState.globalAppearance.fontFamily}, ${appState.globalAppearance.fontSize} pt',
    icon: Icons.font_download_outlined,
    action: () => _edit(context),
  );
}

class _GlobalThemeSetting extends StatelessWidget {
  const _GlobalThemeSetting({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final preset = appState.themePresets
        .where((item) => item.id == appState.globalThemeId)
        .firstOrNull;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xff3d4148))),
      ),
      child: Row(
        children: [
          Icon(
            Icons.palette_outlined,
            size: 18,
            color: appState.globalTheme.foreground,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('Terminal color theme')),
          Text(preset?.name ?? 'Custom'),
          const SizedBox(width: 12),
          PushButton(
            controlSize: ControlSize.regular,
            onPressed: () async {
              final selected = await showTerminalThemeGallery(
                context,
                presets: appState.themePresets,
                selectedPresetId: appState.globalThemeId,
              );
              if (selected != null) {
                await appState.selectGlobalTheme(selected.id);
              }
            },
            child: const Text('Change…'),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.value,
    required this.icon,
    this.action,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xff3d4148))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xffb8c0cc)),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(value, style: const TextStyle(color: Color(0xffa9b0bb))),
          if (action != null) ...[
            const SizedBox(width: 12),
            PushButton(
              controlSize: ControlSize.regular,
              onPressed: action,
              child: const Text('Change…'),
            ),
          ],
        ],
      ),
    );
  }
}

class _FontSettingsSheet extends StatelessWidget {
  const _FontSettingsSheet({
    required this.family,
    required this.size,
    required this.appearance,
  });

  final TextEditingController family;
  final TextEditingController size;
  final TerminalAppearanceProfile appearance;

  @override
  Widget build(BuildContext context) => MacosSheet(
    child: SizedBox(
      width: 440,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Terminal font',
              style: MacosTheme.of(context).typography.title2,
            ),
            const SizedBox(height: 16),
            MacosTextField(controller: family, placeholder: 'Font family'),
            MacosTextField(controller: size, placeholder: 'Font size'),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PushButton(
                  controlSize: ControlSize.regular,
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                PushButton(
                  controlSize: ControlSize.regular,
                  onPressed: () {
                    final parsed = double.tryParse(size.text);
                    if (parsed == null || parsed <= 0) return;
                    Navigator.pop(
                      context,
                      appearance.copyWith(
                        fontFamily: family.text.trim().isEmpty
                            ? 'monospace'
                            : family.text.trim(),
                        fontSize: parsed,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
