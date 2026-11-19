import 'package:flutter/material.dart';

const sessionIcons = <String, IconData>{
  'terminal': Icons.terminal,
  'code': Icons.code,
  'server': Icons.dns,
  'cloud': Icons.cloud_outlined,
  'database': Icons.storage,
  'monitor': Icons.monitor,
  'bug': Icons.bug_report_outlined,
  'settings': Icons.settings_outlined,
  'folder': Icons.folder_outlined,
  'rocket': Icons.rocket_launch_outlined,
};

IconData sessionIcon(String key) => sessionIcons[key] ?? Icons.terminal;
