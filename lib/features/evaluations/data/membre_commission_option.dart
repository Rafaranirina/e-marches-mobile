class MembreCommissionOption {
  const MembreCommissionOption({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
    required this.statut,
    this.prenom,
    this.telephone,
    this.administrationId,
  });

  final String id;
  final String nom;
  final String? prenom;
  final String email;
  final String? telephone;
  final String role;
  final String statut;
  final String? administrationId;

  String get nomComplet {
    final parties = [
      prenom?.trim() ?? '',
      nom.trim(),
    ].where((partie) => partie.isNotEmpty);

    final resultat = parties.join(' ');

    return resultat.isEmpty
        ? 'Utilisateur sans nom'
        : resultat;
  }

  factory MembreCommissionOption.fromJson(
    Map<String, dynamic> json,
  ) {
    return MembreCommissionOption(
      id: json['id']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      prenom: _nullableString(
        json['prenom'],
      ),
      email: json['email']?.toString() ?? '',
      telephone: _nullableString(
        json['telephone'],
      ),
      role: json['role']?.toString() ?? '',
      statut: json['statut']?.toString() ?? '',
      administrationId: _nullableString(
        json['administration_id'],
      ),
    );
  }

  static String? _nullableString(
    dynamic value,
  ) {
    final texte = value?.toString().trim() ?? '';

    return texte.isEmpty ? null : texte;
  }
}