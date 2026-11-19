import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';

import 'theme_presets.dart';
import 'terminal_appearance.dart';
import 'ui/components/terminal_theme_gallery.dart';
import 'ui/pages/profile_home_page.dart';

class SexyTerminalApp extends StatelessWidget {
  const SexyTerminalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosApp(
      title: 'Sexy terminal',
      debugShowCheckedModeBanner: false,
      theme: MacosThemeData.dark().copyWith(
        canvasColor: const Color.fromRGBO(43, 43, 43, 1),
        dividerColor: const Color.fromRGBO(43, 43, 43, 1),
        primaryColor: const Color.fromARGB(255, 79, 161, 255),
      ),
      darkTheme: MacosThemeData.dark().copyWith(
        canvasColor: const Color.fromRGBO(43, 43, 43, 1),
        dividerColor: const Color.fromRGBO(43, 43, 43, 1),
        primaryColor: const Color.fromARGB(255, 75, 159, 255),
      ),
      home: PlatformMenuBar(
        menus: [
          PlatformMenu(
            label: 'Window',
            menus: [
              PlatformMenuItem(
                label: 'New Window',
                shortcut: SingleActivator(LogicalKeyboardKey.keyN, meta: true),
                onSelected: _launchNewWindow,
              ),
              PlatformMenuItem(
                label: 'Close Window',
                shortcut: SingleActivator(LogicalKeyboardKey.keyW, meta: true),
                onSelected: _closeCurrentWindow,
              ),
            ],
          ),
          PlatformMenu(
            label: 'Sexy terminal',
            menus: [
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.quit,
              ),
            ],
          ),
        ],
        child: const _MainNavigation(),
      ),
    );
  }

  static void _launchNewWindow() {
    if (!Platform.isMacOS) return;
    final appBundle = File(Platform.resolvedExecutable)
        .parent
        .parent
        .parent
        .path;
    unawaited(Process.run('/usr/bin/open', ['-n', appBundle]));
  }

  static void _closeCurrentWindow() {
    if (Platform.isMacOS) exit(0);
  }
}

class _MainNavigation extends StatefulWidget {
  const _MainNavigation();

  @override
  State<_MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<_MainNavigation> {
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
                      children: const [ProfileHomePage(), _SettingsPage()],
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
    final store = ThemePresetStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
        children: [
          Text('Settings', style: MacosTheme.of(context).typography.title2),
          const SizedBox(height: 24),
          Text('Appearance', style: MacosTheme.of(context).typography.headline),
          const SizedBox(height: 12),
          _GlobalThemeSetting(store: store),
          _GlobalFontSetting(store: store),
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
  const _GlobalFontSetting({required this.store});

  final ThemePresetStore store;

  Future<void> _edit(BuildContext context) async {
    final family = TextEditingController(
      text: store.globalAppearance.fontFamily,
    );
    final size = TextEditingController(
      text: store.globalAppearance.fontSize.toString(),
    );
    final result = await showMacosSheet<TerminalAppearanceProfile>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _FontSettingsSheet(
        family: family,
        size: size,
        appearance: store.globalAppearance,
      ),
    );
    family.dispose();
    size.dispose();
    if (result != null) await store.updateGlobalAppearance(result);
  }

  @override
  Widget build(BuildContext context) => _SettingRow(
    title: 'Terminal font',
    value:
        '${store.globalAppearance.fontFamily}, ${store.globalAppearance.fontSize} pt',
    icon: Icons.font_download_outlined,
    action: () => _edit(context),
  );
}

class _GlobalThemeSetting extends StatelessWidget {
  const _GlobalThemeSetting({required this.store});

  final ThemePresetStore store;

  @override
  Widget build(BuildContext context) {
    final preset = store.presets
        .where((item) => item.id == store.globalThemeId)
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
            color: store.globalTheme.foreground,
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
                presets: store.presets,
                selectedPresetId: store.globalThemeId,
              );
              if (selected != null) await store.selectGlobalTheme(selected.id);
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
