/// Reproduit côté client la table de transitions de statut appliquée par
/// `appelOffre.controller.js` (PATCH /api/appels-offres/:id/statut) — permet
/// de piloter dynamiquement les actions affichées sans devoir attendre un
/// 409 du serveur. La transition vers `publie` passe par une route dédiée
/// (`/publier`, déjà gérée séparément) et n'apparaît donc pas ici. La
/// transition vers `attribue` est déclenchée par le module Évaluations
/// (`POST /api/evaluations/attribuer`), pas par ce module.
class AppelOffreTransitions {
  const AppelOffreTransitions._();

  static const Map<String, List<String>> _transitionsAutorisees = {
    'brouillon': ['annule'],
    'publie': ['cloture', 'annule'],
    'cloture': ['en_evaluation', 'annule'],
    'en_evaluation': ['infructueux', 'annule'],
    'attribue': [],
    'infructueux': [],
    'annule': [],
  };

  static const Map<String, String> _libelles = {
    'cloture': 'Clôturer',
    'en_evaluation': 'Passer en évaluation',
    'infructueux': 'Déclarer infructueux',
    'annule': 'Annuler',
  };

  /// `true` si `annule`/`infructueux` (motif obligatoire côté backend).
  static bool motifObligatoire(String statutCible) {
    final normalise = statutCible.trim().toLowerCase();

    return normalise == 'annule' || normalise == 'infructueux';
  }

  static List<String> transitionsDisponibles(String statutActuel) {
    return _transitionsAutorisees[statutActuel.trim().toLowerCase()] ??
        const [];
  }

  static String libelleAction(String statutCible) {
    return _libelles[statutCible.trim().toLowerCase()] ??
        statutCible.replaceAll('_', ' ');
  }
}
