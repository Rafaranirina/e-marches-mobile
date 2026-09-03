class Soumission {
  const Soumission({
    required this.id,
    required this.reference,
    required this.statut,
    this.montantPropose,
    this.delaiExecution,
    this.horodatageDepot,
    this.entreprise,
    this.appelOffreId,
    this.appelOffreReference,
    this.appelOffreTitre,
    this.nombreDocuments,
    this.empreinteDepot,
    this.dateCreation,
    this.dateMaj,
  });

  final String id;
  final String reference;
  final double? montantPropose;
  final String? delaiExecution;
  final String statut;
  final DateTime? horodatageDepot;
  final String? entreprise;
  final String? appelOffreId;
  final String? appelOffreReference;
  final String? appelOffreTitre;
  final int? nombreDocuments;
  final String? empreinteDepot;
  final DateTime? dateCreation;
  final DateTime? dateMaj;

  String get statutNormalise => statut.trim().toLowerCase();

  bool get estBrouillon => statutNormalise == 'brouillon';

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
      appelOffreId: _nullableString(
        json['appel_offre_id'],
      ),
      appelOffreReference: _nullableString(
        json['appel_offre_reference'],
      ),
      appelOffreTitre: _nullableString(
        json['appel_offre_titre'],
      ),
      nombreDocuments: _parseInt(
        json['nombre_documents'],
      ),
      empreinteDepot: _nullableString(
        json['empreinte_depot'],
      ),
      dateCreation: _parseDate(
        json['date_creation'],
      ),
      dateMaj: _parseDate(
        json['date_maj'],
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

  static int? _parseInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString().trim());
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

class RecepisseTransmission {
  const RecepisseTransmission({
    required this.reference,
    required this.horodatageDepot,
    required this.empreinteDepot,
    required this.nombreDocuments,
  });

  final String reference;
  final DateTime? horodatageDepot;
  final String empreinteDepot;
  final int nombreDocuments;

  factory RecepisseTransmission.fromJson(
    Map<String, dynamic> json,
  ) {
    return RecepisseTransmission(
      reference: json['reference']?.toString() ?? '',
      horodatageDepot: Soumission._parseDate(
        json['horodatage_depot'],
      ),
      empreinteDepot:
          json['empreinte_depot']?.toString() ?? '',
      nombreDocuments: Soumission._parseInt(
            json['nombre_documents'],
          ) ??
          0,
    );
  }
}
