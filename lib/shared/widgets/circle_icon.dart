import 'package:flutter/material.dart';

/// Icône posée sur un cercle teinté — traitement uniforme des états vides et
/// d'erreur à travers l'app (auparavant une icône nue dupliquée à l'identique
/// dans chaque écran).
class CircleIcon extends StatelessWidget {
  const CircleIcon({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.size = 88,
    this.iconSize = 40,
    super.key,
  });

  /// Cercle neutre (fond `surfaceContainerHighest`), pour un état vide.
  factory CircleIcon.neutre(
    BuildContext context, {
    required IconData icon,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return CircleIcon(
      icon: icon,
      backgroundColor: scheme.surfaceContainerHighest,
      iconColor: scheme.onSurfaceVariant,
    );
  }

  /// Cercle d'erreur (fond `errorContainer`), pour un état d'échec.
  factory CircleIcon.erreur(
    BuildContext context, {
    IconData icon = Icons.error_outline,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return CircleIcon(
      icon: icon,
      backgroundColor: scheme.errorContainer,
      iconColor: scheme.onErrorContainer,
    );
  }

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: iconSize, color: iconColor),
      ),
    );
  }
}
