class ClassementSoumission {
  const ClassementSoumission({
    required this.soumissionId,
    required this.reference,
    required this.statut,
    this.entreprise,
    this.montantPropose,
    this.noteGlobale,
  });

  final String soumissionId;
  final String reference;
  final String? entreprise;
  final double? montantPropose;
  final double? noteGlobale;
  final String statut;

  factory ClassementSoumission.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClassementSoumission(
      soumissionId:
          json['soumission_id']?.toString() ?? '',
      reference:
          json['reference']?.toString() ?? '',
      entreprise: _nullableString(
        json['entreprise'],
      ),
      montantPropose: _parseDouble(
        json['montant_propose'],
      ),
      noteGlobale: _parseDouble(
        json['note_globale'],
      ),
      statut: json['statut']?.toString() ?? '',
    );
  }

  static String? _nullableString(dynamic value) {
    final texte = value?.toString().trim() ?? '';

    return texte.isEmpty ? null : texte;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    final texte = value
        .toString()
        .replaceAll(',', '.')
        .trim();

    if (texte.isEmpty) {
      return null;
    }

    return double.tryParse(texte);
  }
}