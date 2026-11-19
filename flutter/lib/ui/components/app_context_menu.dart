import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

class AppContextMenuAction {
  const AppContextMenuAction({required this.label, required this.onSelected});

  final String label;
  final VoidCallback onSelected;
}

void showAppContextMenu(
  BuildContext context, {
  required Offset globalPosition,
  required List<AppContextMenuAction> actions,
}) {
  final overlay = Overlay.of(context);
  final localPosition = (overlay.context.findRenderObject() as RenderBox)
      .globalToLocal(globalPosition);
  late final OverlayEntry entry;
  void dismiss() => entry.remove();

  entry = OverlayEntry(
    builder: (context) => Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: dismiss,
          ),
        ),
        Positioned(
          left: localPosition.dx,
          top: localPosition.dy,
          child: _AppContextMenu(
            actions: actions,
            onSelected: (action) {
              dismiss();
              action.onSelected();
            },
          ),
        ),
      ],
    ),
  );
  overlay.insert(entry);
}

class ContextMenuButton extends StatelessWidget {
  const ContextMenuButton({super.key, required this.onPressedAt});

  final ValueChanged<Offset> onPressedAt;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (details) => onPressedAt(details.globalPosition),
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: const Padding(
        padding: EdgeInsets.all(6),
        child: Icon(Icons.more_vert, size: 18),
      ),
    ),
  );
}

class _AppContextMenu extends StatelessWidget {
  const _AppContextMenu({required this.actions, required this.onSelected});

  final List<AppContextMenuAction> actions;
  final ValueChanged<AppContextMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    return Container(
      width: 160,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.canvasColor,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final action in actions)
            GestureDetector(
              onTap: () => onSelected(action),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(action.label),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
