import 'auth_user.dart';

class LoginResult {
  const LoginResult({
    required this.statut,
    required this.message,
    this.accessToken,
    this.utilisateur,
    this.utilisateurId,
  });

  final String statut;
  final String message;
  final String? accessToken;
  final AuthUser? utilisateur;
  final String? utilisateurId;

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
      utilisateur: utilisateurJson is Map<String, dynamic>
          ? AuthUser.fromJson(utilisateurJson)
          : null,
    );
  }
}