import 'package:flutter/material.dart';

import '../../../shared/widgets/statut_chip.dart';

/// Statuts d'un contrat, partagés entre la liste (`contrats_page.dart`) et
/// le détail (`contrat_details_page.dart`) — auparavant deux copies
/// littéralement identiques du même widget.
const contratStatutStyles = {
  'en_cours': StatutChipStyle(
    libelle: 'En cours',
    icone: Icons.play_circle_outline,
    couleur: StatutChipCouleur.primaire,
  ),
  'suspendu': StatutChipStyle(
    libelle: 'Suspendu',
    icone: Icons.pause_circle_outline,
    couleur: StatutChipCouleur.secondaire,
  ),
  'termine': StatutChipStyle(
    libelle: 'Terminé',
    icone: Icons.check_circle_outline,
    couleur: StatutChipCouleur.tertiaire,
  ),
  'resilie': StatutChipStyle(
    libelle: 'Résilié',
    icone: Icons.cancel_outlined,
    couleur: StatutChipCouleur.erreur,
  ),
};

const paiementStatutStyles = {
  'paye': StatutChipStyle(
    libelle: 'Payé',
    icone: Icons.check_circle_outline,
    couleur: StatutChipCouleur.primaire,
  ),
  'en_attente': StatutChipStyle(
    libelle: 'En attente',
    icone: Icons.hourglass_empty_outlined,
    couleur: StatutChipCouleur.secondaire,
  ),
};

const jalonStatutStyles = {
  'a_venir': StatutChipStyle(
    libelle: 'À venir',
    icone: Icons.schedule_outlined,
    couleur: StatutChipCouleur.neutre,
  ),
  'en_cours': StatutChipStyle(
    libelle: 'En cours',
    icone: Icons.play_circle_outline,
    couleur: StatutChipCouleur.primaire,
  ),
  'termine': StatutChipStyle(
    libelle: 'Terminé',
    icone: Icons.check_circle_outline,
    couleur: StatutChipCouleur.tertiaire,
  ),
  'retard': StatutChipStyle(
    libelle: 'En retard',
    icone: Icons.warning_amber_outlined,
    couleur: StatutChipCouleur.erreur,
  ),
};
