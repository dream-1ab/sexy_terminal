import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

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
        primaryColor: const Color(0xff8aa4c2),
      ),
      darkTheme: MacosThemeData.dark().copyWith(
        canvasColor: const Color.fromRGBO(43, 43, 43, 1),
        primaryColor: const Color(0xff8aa4c2),
      ),
      home: const _MainNavigation(),
    );
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
      children: [
        Text('Settings', style: MacosTheme.of(context).typography.title2),
        const SizedBox(height: 24),
        Text('Appearance', style: MacosTheme.of(context).typography.headline),
        const SizedBox(height: 12),
        const _SettingRow(
          title: 'Theme',
          value: 'Dark',
          icon: Icons.dark_mode_outlined,
        ),
        const _SettingRow(
          title: 'Terminal font',
          value: 'System monospace',
          icon: Icons.font_download_outlined,
        ),
        const _SettingRow(
          title: 'Terminal font size',
          value: '14 pt',
          icon: Icons.format_size,
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

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
        ],
      ),
    );
  }
}
