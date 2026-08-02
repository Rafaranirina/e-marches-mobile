class Soumission {
  const Soumission({
    required this.id,
    required this.reference,
    required this.statut,
    this.montantPropose,
    this.delaiExecution,
    this.horodatageDepot,
    this.entreprise,
  });

  final String id;
  final String reference;
  final double? montantPropose;
  final String? delaiExecution;
  final String statut;
  final DateTime? horodatageDepot;
  final String? entreprise;

  factory Soumission.fromJson(
    Map<String, dynamic> json,
  ) {
    return Soumission(
      id: json['id']?.toString() ?? '',
      reference:
          json['reference']?.toString() ?? '',
      montantPropose: _parseDouble(
        json['montant_propose'],
      ),
      delaiExecution: _nullableString(
        json['delai_execution'],
      ),
      statut: json['statut']?.toString() ?? '',
      horodatageDepot: _parseDate(
        json['horodatage_depot'],
      ),
      entreprise: _nullableString(
        json['entreprise'],
      ),
    );
  }

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
        .trim();

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