class AuthUser {
  const AuthUser({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    this.administrationId,
    this.entrepriseId,
  });

  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String role;

  final String? administrationId;
  final String? entrepriseId;

  String get nomComplet => '$prenom $nom'.trim();

  bool get estAdministrateurNational =>
      role.trim().toLowerCase() == 'admin_national';

  bool get estAdministration =>
      role.trim().toLowerCase() == 'administration';

  bool get estCommission =>
      role.trim().toLowerCase() == 'commission';

  bool get estFournisseur =>
      role.trim().toLowerCase() == 'fournisseur';

  bool get possedeEntreprise =>
      entrepriseId != null &&
      entrepriseId!.trim().isNotEmpty;

  factory AuthUser.fromJson(
    Map<String, dynamic> json,
  ) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      prenom: json['prenom']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      administrationId: _nullableString(
        json['administration_id'],
      ),
      entrepriseId: _nullableString(
        json['entreprise_id'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'role': role,
      'administration_id': administrationId,
      'entreprise_id': entrepriseId,
    };
  }

  static String? _nullableString(
    dynamic value,
  ) {
    final texte =
        value?.toString().trim() ?? '';

    return texte.isEmpty ? null : texte;
  }
}