class Fournisseur {
  const Fournisseur({
    required this.id,
    required this.raisonSociale,
    this.nif,
    this.stat,
    this.statutValidation,
    this.dateCreation,
  });

  final String id;
  final String raisonSociale;
  final String? nif;
  final String? stat;
  final String? statutValidation;
  final DateTime? dateCreation;

  factory Fournisseur.fromJson(
    Map<String, dynamic> json,
  ) {
    return Fournisseur(
      id: json['id']?.toString() ?? '',
      raisonSociale:
          json['raison_sociale']?.toString() ?? '',
      nif: _nullableString(json['nif']),
      stat: _nullableString(json['stat']),
      statutValidation:
          _nullableString(json['statut_validation']),
      dateCreation: _parseDate(
        json['date_creation'],
      ),
    );
  }

  static String? _nullableString(dynamic value) {
    final texte = value?.toString().trim() ?? '';

    return texte.isEmpty ? null : texte;
  }

  static DateTime? _parseDate(dynamic value) {
    final texte = value?.toString().trim() ?? '';

    if (texte.isEmpty) {
      return null;
    }

    return DateTime.tryParse(texte);
  }
}