import 'package:flutter/material.dart';

import '../../../shared/widgets/statut_chip.dart';

/// Styles des 7 statuts réels d'une soumission, partagés entre la vue
/// administration/commission (`soumissions_page.dart`) et la vue fournisseur
/// (`mes_soumissions_page.dart`) — auparavant deux implémentations de chip
/// dupliquées et divergentes.
const soumissionStatutStyles = {
  'brouillon': StatutChipStyle(
    libelle: 'Brouillon',
    icone: Icons.edit_note_outlined,
    couleur: StatutChipCouleur.neutre,
  ),
  'soumise': StatutChipStyle(
    libelle: 'Transmise',
    icone: Icons.schedule_outlined,
    couleur: StatutChipCouleur.secondaire,
  ),
  'recevable': StatutChipStyle(
    libelle: 'Recevable',
    icone: Icons.verified_outlined,
    couleur: StatutChipCouleur.primaire,
  ),
  'irrecevable': StatutChipStyle(
    libelle: 'Irrecevable',
    icone: Icons.cancel_outlined,
    couleur: StatutChipCouleur.erreur,
  ),
  'evaluee': StatutChipStyle(
    libelle: 'Évaluée',
    icone: Icons.fact_check_outlined,
    couleur: StatutChipCouleur.secondaire,
  ),
  'retenue': StatutChipStyle(
    libelle: 'Retenue',
    icone: Icons.emoji_events_outlined,
    couleur: StatutChipCouleur.primaire,
  ),
  'rejetee': StatutChipStyle(
    libelle: 'Rejetée',
    icone: Icons.block_outlined,
    couleur: StatutChipCouleur.erreur,
  ),
};
