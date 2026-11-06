import 'package:flutter/material.dart';

class DeportesSelectorCard extends StatelessWidget {
  final List<String> deportesFavoritos;
  final VoidCallback onOpenSelector;
  final void Function(String deporte) onRemoveDeporte;
  final IconData Function(String deporte) getDeporteIcon;

  const DeportesSelectorCard({
    super.key,
    required this.deportesFavoritos,
    required this.onOpenSelector,
    required this.onRemoveDeporte,
    required this.getDeporteIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpenSelector,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.sports, color: colors.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mis deportes',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            deportesFavoritos.isEmpty
                                ? 'Seleccionar deportes'
                                : '${deportesFavoritos.length} deportes seleccionados',
                            style: TextStyle(
                              fontSize: 16,
                              color: deportesFavoritos.isEmpty
                                  ? colors.onSurfaceVariant
                                  : colors.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: colors.onSurfaceVariant,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (deportesFavoritos.isNotEmpty) ...[
            Divider(height: 1, color: Theme.of(context).dividerColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: deportesFavoritos
                    .map(
                      (deporte) => _DeporteChip(
                        deporte: deporte,
                        icon: getDeporteIcon(deporte),
                        onRemove: () => onRemoveDeporte(deporte),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeporteChip extends StatelessWidget {
  final String deporte;
  final IconData icon;
  final VoidCallback onRemove;

  const _DeporteChip({
    required this.deporte,
    required this.icon,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.primary.withValues(alpha: .45),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.secondary),
          const SizedBox(width: 6),
          Text(
            deporte,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 16, color: colors.secondary),
          ),
        ],
      ),
    );
  }
}
