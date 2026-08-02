class Paiement {
  const Paiement({
    required this.id,
    required this.contratId,
    required this.statut,
    this.reference,
    this.description,
    this.montant,
    this.dateEcheance,
    this.datePaiement,
    this.validePar,
    this.dateCreation,
  });

  final String id;
  final String contratId;
  final String? reference;
  final String? description;
  final double? montant;
  final String statut;
  final DateTime? dateEcheance;
  final DateTime? datePaiement;
  final String? validePar;
  final DateTime? dateCreation;

  factory Paiement.fromJson(
    Map<String, dynamic> json,
  ) {
    return Paiement(
      id: json['id']?.toString() ?? '',
      contratId:
          json['contrat_id']?.toString() ?? '',
      reference: _nullableString(
        json['reference'],
      ),
      description: _nullableString(
        json['description'],
      ),
      montant: _parseDouble(
        json['montant'],
      ),
      statut:
          json['statut']?.toString() ?? '',
      dateEcheance: _parseDate(
        json['date_echeance'],
      ),
      datePaiement: _parseDate(
        json['date_paiement'],
      ),
      validePar: _nullableString(
        json['valide_par'],
      ),
      dateCreation: _parseDate(
        json['date_creation'],
      ),
    );
  }

  bool get estEnAttente =>
      statut.trim().toLowerCase() ==
      'en_attente';

  bool get estPaye =>
      statut.trim().toLowerCase() ==
      'paye';

  static String? _nullableString(
    dynamic value,
  ) {
    final texte =
        value?.toString().trim() ?? '';

    return texte.isEmpty ? null : texte;
  }

  static double? _parseDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    final texte = value
        .toString()
        .replaceAll(',', '.')
        .replaceAll(
          RegExp(r'\s+'),
          '',
        )
        .trim();

    if (texte.isEmpty) {
      return null;
    }

    return double.tryParse(texte);
  }

  static DateTime? _parseDate(
    dynamic value,
  ) {
    final texte =
        value?.toString().trim() ?? '';

    if (texte.isEmpty) {
      return null;
    }

    return DateTime.tryParse(texte);
  }
}