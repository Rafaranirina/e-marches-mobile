import 'package:flutter/material.dart';

/// Palette générique réutilisée par [StatutChip] — mappée sur les
/// conteneurs de `ColorScheme` pour rester cohérente avec le thème
/// Material 3 de l'app (clair/sombre) sans que chaque feature ait à
/// ré-implémenter son propre choix de couleurs.
enum StatutChipCouleur { primaire, secondaire, tertiaire, erreur, neutre }

class StatutChipStyle {
  const StatutChipStyle({
    required this.libelle,
    required this.icone,
    required this.couleur,
  });

  final String libelle;
  final IconData icone;
  final StatutChipCouleur couleur;
}

/// Widget de statut générique paramétrable par une table `statut -> style`,
/// destiné à remplacer les nombreuses implémentations quasi identiques de
/// chip de statut dupliquées à travers les features (appels_offres,
/// soumissions, contrats, evaluations, fournisseurs, utilisateurs/profil).
///
/// Chaque feature garde son propre fichier de définitions de statuts
/// (ex. `soumission_statut_styles.dart`) plutôt que de centraliser la
/// logique métier ici — ce widget ne connaît que la présentation.
class StatutChip extends StatelessWidget {
  const StatutChip({
    required this.statut,
    required this.styles,
    super.key,
  });

  final String statut;
  final Map<String, StatutChipStyle> styles;

  @override
  Widget build(BuildContext context) {
    final statutNormalise = statut.trim().toLowerCase();
    final couleurs = Theme.of(context).colorScheme;

    final style = styles[statutNormalise] ??
        StatutChipStyle(
          libelle: statutNormalise.isEmpty
              ? 'Non défini'
              : statut.replaceAll('_', ' '),
          icone: Icons.info_outline,
          couleur: StatutChipCouleur.neutre,
        );

    final (fond, premierPlan) = _resoudreCouleurs(
      couleurs,
      style.couleur,
    );

    return Chip(
      backgroundColor: fond,
      side: BorderSide.none,
      avatar: Icon(style.icone, size: 17, color: premierPlan),
      label: Text(
        style.libelle,
        style: TextStyle(
          color: premierPlan,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static (Color, Color) _resoudreCouleurs(
    ColorScheme couleurs,
    StatutChipCouleur couleur,
  ) {
    switch (couleur) {
      case StatutChipCouleur.primaire:
        return (couleurs.primaryContainer, couleurs.onPrimaryContainer);

      case StatutChipCouleur.secondaire:
        return (
          couleurs.secondaryContainer,
          couleurs.onSecondaryContainer,
        );

      case StatutChipCouleur.tertiaire:
        return (couleurs.tertiaryContainer, couleurs.onTertiaryContainer);

      case StatutChipCouleur.erreur:
        return (couleurs.errorContainer, couleurs.onErrorContainer);

      case StatutChipCouleur.neutre:
        return (
          couleurs.surfaceContainerHighest,
          couleurs.onSurfaceVariant,
        );
    }
  }
}
