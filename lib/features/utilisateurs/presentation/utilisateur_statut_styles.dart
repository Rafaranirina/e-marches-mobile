import 'package:flutter/material.dart';

import '../../../shared/widgets/statut_chip.dart';

/// Statuts d'un compte utilisateur, partagés entre `utilisateurs_page.dart`
/// (gestion, admin_national) et `profil_page.dart` (lecture seule, tous
/// rôles) — les deux affichaient auparavant une copie identique du même
/// widget.
const utilisateurStatutStyles = {
  'actif': StatutChipStyle(
    libelle: 'Actif',
    icone: Icons.check_circle_outline,
    couleur: StatutChipCouleur.primaire,
  ),
  'en_attente': StatutChipStyle(
    libelle: 'En attente',
    icone: Icons.hourglass_empty_outlined,
    couleur: StatutChipCouleur.secondaire,
  ),
  'suspendu': StatutChipStyle(
    libelle: 'Suspendu',
    icone: Icons.pause_circle_outline,
    couleur: StatutChipCouleur.erreur,
  ),
  'inactif': StatutChipStyle(
    libelle: 'Inactif',
    icone: Icons.block_outlined,
    couleur: StatutChipCouleur.neutre,
  ),
};
