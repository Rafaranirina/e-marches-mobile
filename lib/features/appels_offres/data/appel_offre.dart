class AppelOffre {
  const AppelOffre({
    required this.id,
    required this.reference,
    required this.titre,
    required this.typeMarche,
    required this.statut,
    this.description,
    this.categorieId,
    this.categorieNom,
    this.administrationId,
    this.administrationNom,
    this.administrationSigle,
    this.montantEstime,
    this.datePublication,
    this.dateLimiteSoumission,
    this.dateOuverturePlis,
    this.dateCreation,
    this.dateMaj,
  });

  final String id;
  final String reference;
  final String titre;
  final String typeMarche;
  final String statut;

  final String? description;
  final String? categorieId;
  final String? categorieNom;
  final String? administrationId;
  final String? administrationNom;
  final String? administrationSigle;

  final double? montantEstime;

  final DateTime? datePublication;
  final DateTime? dateLimiteSoumission;
  final DateTime? dateOuverturePlis;
  final DateTime? dateCreation;
  final DateTime? dateMaj;

  factory AppelOffre.fromJson(Map<String, dynamic> json) {
    return AppelOffre(
      id: json['id']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      titre: json['titre']?.toString() ?? '',
      description: json['description']?.toString(),
      typeMarche: json['type_marche']?.toString() ?? '',
      categorieId: json['categorie_id']?.toString(),
      categorieNom: json['categorie_nom']?.toString(),
      administrationId: json['administration_id']?.toString(),
      administrationNom: json['administration_nom']?.toString(),
      administrationSigle: json['administration_sigle']?.toString(),
      montantEstime: _parseDouble(json['montant_estime']),
      statut: json['statut']?.toString() ?? '',
      datePublication: _parseDate(json['date_publication']),
      dateLimiteSoumission:
          _parseDate(json['date_limite_soumission']),
      dateOuverturePlis: _parseDate(json['date_ouverture_plis']),
      dateCreation: _parseDate(json['date_creation']),
      dateMaj: _parseDate(json['date_maj']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().replaceAll(',', '.'),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
