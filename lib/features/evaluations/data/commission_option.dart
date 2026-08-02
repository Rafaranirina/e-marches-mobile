class CommissionOption {
  const CommissionOption({
    required this.id,
    required this.nom,
    this.appelOffreId,
    this.dateCreation,
    this.membres = const [],
  });

  final String id;
  final String nom;
  final String? appelOffreId;
  final DateTime? dateCreation;
  final List<MembreCommission> membres;

  factory CommissionOption.fromJson(
    Map<String, dynamic> json,
  ) {
    final membresJson = json['membres'];

    return CommissionOption(
      id: json['id']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      appelOffreId: _nullableString(
        json['appel_offre_id'],
      ),
      dateCreation: _parseDate(
        json['date_creation'],
      ),
      membres: membresJson is List
          ? membresJson
              .whereType<Map>()
              .map(
                (membre) => MembreCommission.fromJson(
                  Map<String, dynamic>.from(membre),
                ),
              )
              .toList()
          : const [],
    );
  }

  static String? _nullableString(
    dynamic value,
  ) {
    final texte = value?.toString().trim() ?? '';

    return texte.isEmpty ? null : texte;
  }

  static DateTime? _parseDate(
    dynamic value,
  ) {
    final texte = value?.toString().trim() ?? '';

    if (texte.isEmpty) {
      return null;
    }

    return DateTime.tryParse(texte);
  }
}

class MembreCommission {
  const MembreCommission({
    required this.utilisateurId,
    this.fonction,
  });

  final String utilisateurId;
  final String? fonction;

  factory MembreCommission.fromJson(
    Map<String, dynamic> json,
  ) {
    return MembreCommission(
      utilisateurId:
          json['utilisateur_id']?.toString() ?? '',
      fonction: _nullableString(
        json['fonction'],
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