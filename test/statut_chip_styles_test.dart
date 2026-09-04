import 'package:e_marches_mobile/features/appels_offres/presentation/appel_offre_statut_styles.dart';
import 'package:e_marches_mobile/features/contrats/presentation/contrat_statut_styles.dart';
import 'package:e_marches_mobile/features/soumissions/presentation/soumission_statut_styles.dart';
import 'package:e_marches_mobile/features/utilisateurs/presentation/utilisateur_statut_styles.dart';
import 'package:e_marches_mobile/shared/widgets/actif_statut_styles.dart';
import 'package:flutter_test/flutter_test.dart';

// Garde-fou contre la classe de bug rencontrée à répétition pendant ce
// projet : une carte de styles de statut qui oublie une valeur réellement
// renvoyée par le backend (ex. appels d'offres sans "en_evaluation", ou
// soumissions sans "rejetee") fait retomber le chip sur un libellé
// générique/gris au lieu du bon statut — sans erreur de compilation ni de
// runtime, donc invisible sans ce test. Les listes ci-dessous reflètent les
// enums Postgres exacts documentés côté backend.
void main() {
  test('appelOffreStatutStyles couvre les 7 statuts réels', () {
    expect(
      appelOffreStatutStyles.keys.toSet(),
      {
        'brouillon',
        'publie',
        'cloture',
        'en_evaluation',
        'attribue',
        'infructueux',
        'annule',
      },
    );
  });

  test('soumissionStatutStyles couvre les 7 statuts réels', () {
    expect(
      soumissionStatutStyles.keys.toSet(),
      {
        'brouillon',
        'soumise',
        'recevable',
        'irrecevable',
        'evaluee',
        'retenue',
        'rejetee',
      },
    );
  });

  test('contratStatutStyles couvre les 4 statuts réels', () {
    expect(
      contratStatutStyles.keys.toSet(),
      {'en_cours', 'suspendu', 'termine', 'resilie'},
    );
  });

  test('paiementStatutStyles couvre les 2 statuts réels', () {
    expect(paiementStatutStyles.keys.toSet(), {'en_attente', 'paye'});
  });

  test('jalonStatutStyles couvre les 4 statuts réels', () {
    expect(
      jalonStatutStyles.keys.toSet(),
      {'a_venir', 'en_cours', 'termine', 'retard'},
    );
  });

  test('utilisateurStatutStyles couvre les 4 statuts réels', () {
    expect(
      utilisateurStatutStyles.keys.toSet(),
      {'actif', 'en_attente', 'suspendu', 'inactif'},
    );
  });

  test('actifStatutStyles couvre les 2 états booléens', () {
    expect(actifStatutStyles.keys.toSet(), {'actif', 'inactif'});
    expect(cleActifStatut(true), 'actif');
    expect(cleActifStatut(false), 'inactif');
  });
}
