import 'package:flutter/material.dart';

import 'statut_chip.dart';

/// Styles du statut actif/inactif (booléen) partagé par les référentiels
/// simples — administrations, catégories — qui n'ont que ces deux états.
const actifStatutStyles = {
  'actif': StatutChipStyle(
    libelle: 'Active',
    icone: Icons.check_circle_outline,
    couleur: StatutChipCouleur.primaire,
  ),
  'inactif': StatutChipStyle(
    libelle: 'Inactive',
    icone: Icons.block_outlined,
    couleur: StatutChipCouleur.neutre,
  ),
};

/// Convertit un booléen `actif` en clé compatible avec [actifStatutStyles].
String cleActifStatut(bool actif) => actif ? 'actif' : 'inactif';
