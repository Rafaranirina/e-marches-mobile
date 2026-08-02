class Contrat {
  const Contrat({
    required this.id,
    required this.reference,
    required this.statut,
    this.objet,
    this.montant,
    this.dateSignature,
    this.dateDebut,
    this.dateFin,
    this.entreprise,
    this.administration,
    this.appelOffre,
    this.appelOffreId,
    this.entrepriseId,
    this.administrationId,
    this.soumissionId,
    this.dateCreation,
  });

  final String id;
  final String reference;
  final String? objet;
  final double? montant;
  final String statut;

  final DateTime? dateSignature;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final DateTime? dateCreation;

  final String? entreprise;
  final String? administration;
  final String? appelOffre;

  final String? appelOffreId;
  final String? entrepriseId;
  final String? administrationId;
  final String? soumissionId;

  factory Contrat.fromJson(
    Map<String, dynamic> json,
  ) {
    return Contrat(
      id: json['id']?.toString() ?? '',
      reference:
          json['reference']?.toString() ?? '',
      objet: _nullableString(
        json['objet'],
      ),
      montant: _parseDouble(
        json['montant'],
      ),
      statut:
          json['statut']?.toString() ?? '',
      dateSignature: _parseDate(
        json['date_signature'],
      ),
      dateDebut: _parseDate(
        json['date_debut'],
      ),
      dateFin: _parseDate(
        json['date_fin'],
      ),
      dateCreation: _parseDate(
        json['date_creation'],
      ),
      entreprise: _nullableString(
        json['entreprise'],
      ),
      administration: _nullableString(
        json['administration'],
      ),
      appelOffre: _nullableString(
        json['appel_offre'],
      ),
      appelOffreId: _nullableString(
        json['appel_offre_id'],
      ),
      entrepriseId: _nullableString(
        json['entreprise_id'],
      ),
      administrationId: _nullableString(
        json['administration_id'],
      ),
      soumissionId: _nullableString(
        json['soumission_id'],
      ),
    );
  }

  bool get estEnCours =>
      statut.trim().toLowerCase() ==
      'en_cours';

  bool get estSuspendu =>
      statut.trim().toLowerCase() ==
      'suspendu';

  bool get estTermine =>
      statut.trim().toLowerCase() ==
      'termine';

  bool get estResilie =>
      statut.trim().toLowerCase() ==
      'resilie';

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