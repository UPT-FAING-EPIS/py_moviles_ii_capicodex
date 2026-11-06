import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'theme_controller.dart';

/// El mismo selector de apariencia para deportista, gestor y administrador.
class VisualThemePicker extends StatelessWidget {
  final Color? iconColor;
  const VisualThemePicker({super.key, this.iconColor});

  static String name(AppVisualTheme value) => switch (value) {
    AppVisualTheme.light => 'Claro',
    AppVisualTheme.dark => 'Oscuro',
    AppVisualTheme.football => 'Fútbol',
    AppVisualTheme.wimbledon => 'Tenis Wimbledon',
    AppVisualTheme.rolandGarros => 'Tenis Roland Garros',
    AppVisualTheme.usOpen => 'Tenis US Open',
    AppVisualTheme.volleyball => 'Vóley',
    AppVisualTheme.basketball => 'Básquet',
  };

  static IconData icon(AppVisualTheme value) => switch (value) {
    AppVisualTheme.light => Icons.light_mode_outlined,
    AppVisualTheme.dark => Icons.dark_mode_outlined,
    AppVisualTheme.football => Icons.sports_soccer_outlined,
    AppVisualTheme.wimbledon ||
    AppVisualTheme.rolandGarros ||
    AppVisualTheme.usOpen => Icons.sports_tennis_outlined,
    AppVisualTheme.volleyball => Icons.sports_volleyball_outlined,
    AppVisualTheme.basketball => Icons.sports_basketball_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final colors = Theme.of(context).colorScheme;
    return PopupMenuButton<AppVisualTheme>(
      tooltip: 'Cambiar tema visual',
      icon: Icon(icon(controller.selection), color: iconColor ?? Colors.white),
      color: colors.surface,
      onSelected: (selection) => controller.select(selection),
      itemBuilder: (_) => [
        for (final selection in AppVisualTheme.values)
          PopupMenuItem(
            value: selection,
            child: Row(
              children: [
                Icon(icon(selection), color: colors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(name(selection))),
                if (selection == controller.selection)
                  Icon(Icons.check, color: colors.secondary, size: 20),
              ],
            ),
          ),
      ],
    );
  }
}
