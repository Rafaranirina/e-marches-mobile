class StatistiquesTableauBord {
  const StatistiquesTableauBord({
    required this.totalAppelsOffres,
    required this.appelsPublies,
    required this.appelsAttribues,
    required this.totalSoumissions,
    required this.totalContrats,
    required this.totalEntreprises,
    required this.montantTotalContrats,
    required this.appelsParStatut,
    required this.appelsParType,
  });

  final int totalAppelsOffres;
  final int appelsPublies;
  final int appelsAttribues;
  final int totalSoumissions;
  final int totalContrats;
  final int totalEntreprises;
  final double montantTotalContrats;

  final List<RepartitionAppelOffre> appelsParStatut;
  final List<RepartitionAppelOffre> appelsParType;

  factory StatistiquesTableauBord.fromJson(
    Map<String, dynamic> json,
  ) {
    final compteurs =
        _convertirMap(json['compteurs']);

    return StatistiquesTableauBord(
      totalAppelsOffres: _parseInt(
        compteurs['total_appels_offres'],
      ),
      appelsPublies: _parseInt(
        compteurs['appels_publies'],
      ),
      appelsAttribues: _parseInt(
        compteurs['appels_attribues'],
      ),
      totalSoumissions: _parseInt(
        compteurs['total_soumissions'],
      ),
      totalContrats: _parseInt(
        compteurs['total_contrats'],
      ),
      totalEntreprises: _parseInt(
        compteurs['total_entreprises'],
      ),
      montantTotalContrats: _parseDouble(
        compteurs['montant_total_contrats'],
      ),
      appelsParStatut: _convertirListe(
        json['appels_par_statut'],
      )
          .map(
            RepartitionAppelOffre.fromJson,
          )
          .toList(),
      appelsParType: _convertirListe(
        json['appels_par_type'],
      )
          .map(
            RepartitionAppelOffre.fromJson,
          )
          .toList(),
    );
  }

  static const vide =
      StatistiquesTableauBord(
    totalAppelsOffres: 0,
    appelsPublies: 0,
    appelsAttribues: 0,
    totalSoumissions: 0,
    totalContrats: 0,
    totalEntreprises: 0,
    montantTotalContrats: 0,
    appelsParStatut: [],
    appelsParType: [],
  );
}

class RepartitionAppelOffre {
  const RepartitionAppelOffre({
    required this.libelle,
    required this.nombre,
  });

  final String libelle;
  final int nombre;

  factory RepartitionAppelOffre.fromJson(
    Map<String, dynamic> json,
  ) {
    final libelle =
        json['statut'] ??
            json['type_marche'];

    return RepartitionAppelOffre(
      libelle:
          libelle?.toString().trim() ?? '',
      nombre: _parseInt(
        json['nombre'],
      ),
    );
  }
}

class TopEntreprise {
  const TopEntreprise({
    required this.entreprise,
    required this.nombreContrats,
    required this.montantTotal,
  });

  final String entreprise;
  final int nombreContrats;
  final double montantTotal;

  factory TopEntreprise.fromJson(
    Map<String, dynamic> json,
  ) {
    return TopEntreprise(
      entreprise:
          json['entreprise']
                  ?.toString()
                  .trim() ??
              '',
      nombreContrats: _parseInt(
        json['nombre_contrats'],
      ),
      montantTotal: _parseDouble(
        json['montant_total'],
      ),
    );
  }
}

class ActiviteRecente {
  const ActiviteRecente({
    required this.reference,
    required this.titre,
    required this.statut,
    required this.administration,
    this.dateCreation,
  });

  final String reference;
  final String titre;
  final String statut;
  final String administration;
  final DateTime? dateCreation;

  factory ActiviteRecente.fromJson(
    Map<String, dynamic> json,
  ) {
    return ActiviteRecente(
      reference:
          json['reference']
                  ?.toString()
                  .trim() ??
              '',
      titre:
          json['titre']
                  ?.toString()
                  .trim() ??
              '',
      statut:
          json['statut']
                  ?.toString()
                  .trim() ??
              '',
      administration:
          json['administration']
                  ?.toString()
                  .trim() ??
              '',
      dateCreation: _parseDate(
        json['date_creation'],
      ),
    );
  }
}

Map<String, dynamic> _convertirMap(
  dynamic valeur,
) {
  if (valeur is! Map) {
    return <String, dynamic>{};
  }

  return Map<String, dynamic>.from(
    valeur,
  );
}

List<Map<String, dynamic>> _convertirListe(
  dynamic valeur,
) {
  if (valeur is! List) {
    return <Map<String, dynamic>>[];
  }

  return valeur
      .whereType<Map>()
      .map(
        (element) =>
            Map<String, dynamic>.from(
          element,
        ),
      )
      .toList();
}

int _parseInt(
  dynamic valeur,
) {
  if (valeur == null) {
    return 0;
  }

  if (valeur is int) {
    return valeur;
  }

  if (valeur is num) {
    return valeur.toInt();
  }

  final texte =
      valeur.toString().trim();

  if (texte.isEmpty) {
    return 0;
  }

  return int.tryParse(texte) ??
      double.tryParse(texte)?.toInt() ??
      0;
}

double _parseDouble(
  dynamic valeur,
) {
  if (valeur == null) {
    return 0;
  }

  if (valeur is num) {
    return valeur.toDouble();
  }

  final texte = valeur
      .toString()
      .trim()
      .replaceAll(',', '.');

  if (texte.isEmpty) {
    return 0;
  }

  return double.tryParse(texte) ?? 0;
}

DateTime? _parseDate(
  dynamic valeur,
) {
  final texte =
      valeur?.toString().trim() ?? '';

  if (texte.isEmpty) {
    return null;
  }

  return DateTime.tryParse(texte);
}