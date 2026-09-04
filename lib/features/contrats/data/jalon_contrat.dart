class JalonContrat {
  const JalonContrat({
    required this.id,
    required this.contratId,
    required this.titre,
    required this.statut,
    this.description,
    this.ordre = 0,
    this.datePrevue,
    this.dateReelle,
    this.creePar,
    this.dateMaj,
  });

  final String id;
  final String contratId;
  final String titre;
  final String? description;
  final int ordre;
  final String statut;
  final DateTime? datePrevue;
  final DateTime? dateReelle;
  final String? creePar;
  final DateTime? dateMaj;

  factory JalonContrat.fromJson(
    Map<String, dynamic> json,
  ) {
    return JalonContrat(
      id: json['id']?.toString() ?? '',
      contratId:
          json['contrat_id']?.toString() ?? '',
      titre: json['titre']?.toString() ?? '',
      description: _nullableString(
        json['description'],
      ),
      ordre: _parseInt(
            json['ordre'],
          ) ??
          0,
      statut:
          json['statut']?.toString() ?? '',
      datePrevue: _parseDate(
        json['date_prevue'],
      ),
      dateReelle: _parseDate(
        json['date_reelle'],
      ),
      creePar: _nullableString(
        json['cree_par'],
      ),
      dateMaj: _parseDate(
        json['date_maj'],
      ),
    );
  }

  bool get estAVenir =>
      statut.trim().toLowerCase() ==
      'a_venir';

  bool get estEnCours =>
      statut.trim().toLowerCase() ==
      'en_cours';

  bool get estTermine =>
      statut.trim().toLowerCase() ==
      'termine';

  bool get estEnRetard =>
      statut.trim().toLowerCase() ==
      'retard';

  String get statutLibelle {
    switch (statut.trim().toLowerCase()) {
      case 'a_venir':
        return 'À venir';

      case 'en_cours':
        return 'En cours';

      case 'termine':
        return 'Terminé';

      case 'retard':
        return 'En retard';

      default:
        return statut.trim().isEmpty
            ? 'Non défini'
            : statut.replaceAll('_', ' ');
    }
  }

  static String? _nullableString(
    dynamic value,
  ) {
    final texte =
        value?.toString().trim() ?? '';

    return texte.isEmpty ? null : texte;
  }

  static int? _parseInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    final texte = value.toString().trim();

    if (texte.isEmpty) {
      return null;
    }

    return int.tryParse(texte) ??
        double.tryParse(texte)?.toInt();
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
