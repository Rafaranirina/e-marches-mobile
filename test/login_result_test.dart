import 'package:e_marches_mobile/features/auth/data/login_result.dart';
import 'package:flutter_test/flutter_test.dart';

// Verrouille le parsing de la réponse de connexion — en particulier
// `challenge_2fa`, qui n'était pas lu avant la correction du flux 2FA (le
// mobile ne pouvait alors jamais terminer une connexion avec double
// authentification activée) et `accessToken`, seul champ camelCase de toute
// l'API (confirmé côté backend, ce n'est pas une faute de frappe côté
// mobile).
void main() {
  group('LoginResult.fromJson', () {
    test('connexion réussie sans 2FA', () {
      final result = LoginResult.fromJson({
        'statut': 'ok',
        'message': 'Connexion réussie.',
        'accessToken': 'jwt.token.ici',
        'utilisateur': {
          'id': 'u-1',
          'nom': 'Rakoto',
          'prenom': 'Jean',
          'email': 'jean@example.mg',
          'role': 'fournisseur',
        },
      });

      expect(result.isSuccess, isTrue);
      expect(result.requiresTwoFactor, isFalse);
      expect(result.accessToken, 'jwt.token.ici');
      expect(result.utilisateur?.email, 'jean@example.mg');
      expect(result.challenge2fa, isNull);
    });

    test('2FA requise : challenge_2fa doit être capturé', () {
      final result = LoginResult.fromJson({
        'statut': '2fa_requis',
        'message': 'Code de vérification requis.',
        'utilisateur_id': 'u-2',
        'challenge_2fa': 'challenge.jwt.court',
      });

      expect(result.requiresTwoFactor, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.utilisateurId, 'u-2');
      expect(result.challenge2fa, 'challenge.jwt.court');
      // Pas encore de session à ce stade.
      expect(result.accessToken, isNull);
      expect(result.utilisateur, isNull);
    });

    test('échec de connexion', () {
      final result = LoginResult.fromJson({
        'statut': 'erreur',
        'message': 'Identifiants invalides.',
      });

      expect(result.isError, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.requiresTwoFactor, isFalse);
    });

    test('statut manquant retombe sur erreur', () {
      final result = LoginResult.fromJson({});

      expect(result.statut, 'erreur');
      expect(result.isError, isTrue);
    });
  });
}
