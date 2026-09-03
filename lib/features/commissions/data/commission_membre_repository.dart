import '../../utilisateurs/data/utilisateur_gestion.dart';

class CommissionMembreRepository {
  // TODO(backend): aucune route backend n'expose la liste des utilisateurs
  // éligibles à une commission (l'ancienne cible '/api/users/membres-commission'
  // n'existe pas dans user.routes.js, confirmé par grep exhaustif). On lève
  // immédiatement une erreur explicite plutôt que d'appeler un endpoint
  // inexistant (404 silencieux) — voir audit du 2026-09-03.
  Future<List<UtilisateurGestion>> listerMembresDisponibles() async {
    throw const CommissionMembreException(
      'Fonctionnalité indisponible : aucun endpoint backend ne permet '
      'actuellement de lister les membres éligibles à une commission.',
    );
  }
}

class CommissionMembreException implements Exception {
  const CommissionMembreException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}
