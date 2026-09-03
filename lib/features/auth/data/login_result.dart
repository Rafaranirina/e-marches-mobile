import 'auth_user.dart';

class LoginResult {
  const LoginResult({
    required this.statut,
    required this.message,
    this.accessToken,
    this.utilisateur,
    this.utilisateurId,
    this.challenge2fa,
  });

  final String statut;
  final String message;
  // Le backend renvoie bien ce champ en camelCase (seul champ camelCase de
  // toute l'API, qui est sinon entièrement en snake_case) — ce n'est pas une
  // faute de frappe côté mobile, ne pas "corriger" en access_token.
  final String? accessToken;
  final AuthUser? utilisateur;
  final String? utilisateurId;
  final String? challenge2fa;

  bool get isSuccess => statut == 'ok';

  bool get requiresTwoFactor => statut == '2fa_requis';

  bool get isError => statut == 'erreur';

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final utilisateurJson = json['utilisateur'];

    return LoginResult(
      statut: json['statut']?.toString() ?? 'erreur',
      message: json['message']?.toString() ?? 'Une erreur est survenue.',
      accessToken: json['accessToken']?.toString(),
      utilisateurId: json['utilisateur_id']?.toString(),
      challenge2fa: json['challenge_2fa']?.toString(),
      utilisateur: utilisateurJson is Map<String, dynamic>
          ? AuthUser.fromJson(utilisateurJson)
          : null,
    );
  }
}