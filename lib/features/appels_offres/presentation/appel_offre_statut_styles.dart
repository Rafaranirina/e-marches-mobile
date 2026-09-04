import 'package:flutter/material.dart';

import '../../../shared/widgets/statut_chip.dart';

/// Styles des 7 statuts réels d'un appel d'offres, partagés entre la liste
/// (`appels_offres_page.dart`) et le détail (`appel_offre_details_page.dart`).
const appelOffreStatutStyles = {
  'brouillon': StatutChipStyle(
    libelle: 'Brouillon',
    icone: Icons.edit_note_outlined,
    couleur: StatutChipCouleur.secondaire,
  ),
  'publie': StatutChipStyle(
    libelle: 'Publié',
    icone: Icons.public_outlined,
    couleur: StatutChipCouleur.primaire,
  ),
  'cloture': StatutChipStyle(
    libelle: 'Clôturé',
    icone: Icons.event_busy_outlined,
    couleur: StatutChipCouleur.tertiaire,
  ),
  'en_evaluation': StatutChipStyle(
    libelle: 'En évaluation',
    icone: Icons.leaderboard_outlined,
    couleur: StatutChipCouleur.tertiaire,
  ),
  'attribue': StatutChipStyle(
    libelle: 'Attribué',
    icone: Icons.verified_outlined,
    couleur: StatutChipCouleur.primaire,
  ),
  'infructueux': StatutChipStyle(
    libelle: 'Infructueux',
    icone: Icons.block_outlined,
    couleur: StatutChipCouleur.erreur,
  ),
  'annule': StatutChipStyle(
    libelle: 'Annulé',
    icone: Icons.cancel_outlined,
    couleur: StatutChipCouleur.erreur,
  ),
};

/// Libellé français d'un statut d'appel d'offres — utilisé hors du chip
/// (ex. dans les dialogues de confirmation de transition et l'historique).
String libelleStatutAppelOffre(String statut) {
  final normalise = statut.trim().toLowerCase();
  final style = appelOffreStatutStyles[normalise];

  if (style != null) {
    return style.libelle;
  }

  return normalise.isEmpty ? 'Non défini' : statut.replaceAll('_', ' ');
}
