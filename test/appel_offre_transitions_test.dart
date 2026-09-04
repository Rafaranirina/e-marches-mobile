import 'package:e_marches_mobile/features/appels_offres/data/appel_offre_transitions.dart';
import 'package:flutter_test/flutter_test.dart';

// Verrouille la table de transitions reproduite depuis le backend
// (appelOffre.controller.js) — c'est ce qui pilote les boutons d'action
// affichés sur l'écran de détail. Une régression ici ferait apparaître un
// bouton pour une transition que le serveur refuserait (409), ou en ferait
// disparaître une qui devrait être disponible.
void main() {
  group('AppelOffreTransitions.transitionsDisponibles', () {
    test('brouillon ne permet que annule', () {
      expect(
        AppelOffreTransitions.transitionsDisponibles('brouillon'),
        ['annule'],
      );
    });

    test('publie permet cloture et annule', () {
      expect(
        AppelOffreTransitions.transitionsDisponibles('publie'),
        ['cloture', 'annule'],
      );
    });

    test('cloture permet en_evaluation et annule', () {
      expect(
        AppelOffreTransitions.transitionsDisponibles('cloture'),
        ['en_evaluation', 'annule'],
      );
    });

    test('en_evaluation permet infructueux et annule (pas attribue)', () {
      final transitions =
          AppelOffreTransitions.transitionsDisponibles('en_evaluation');

      expect(transitions, containsAll(['infructueux', 'annule']));
      // L'attribution passe par le module Évaluations
      // (POST /api/evaluations/attribuer), pas par ce module.
      expect(transitions, isNot(contains('attribue')));
    });

    test('les statuts terminaux ne permettent aucune transition', () {
      for (final statutTerminal in ['attribue', 'infructueux', 'annule']) {
        expect(
          AppelOffreTransitions.transitionsDisponibles(statutTerminal),
          isEmpty,
          reason: '$statutTerminal doit être terminal',
        );
      }
    });

    test('insensible à la casse et aux espaces', () {
      expect(
        AppelOffreTransitions.transitionsDisponibles('  PUBLIE  '),
        ['cloture', 'annule'],
      );
    });
  });

  group('AppelOffreTransitions.motifObligatoire', () {
    test('obligatoire pour annule et infructueux', () {
      expect(AppelOffreTransitions.motifObligatoire('annule'), isTrue);
      expect(AppelOffreTransitions.motifObligatoire('infructueux'), isTrue);
    });

    test('facultatif pour les autres transitions', () {
      expect(AppelOffreTransitions.motifObligatoire('cloture'), isFalse);
      expect(
        AppelOffreTransitions.motifObligatoire('en_evaluation'),
        isFalse,
      );
    });
  });
}
