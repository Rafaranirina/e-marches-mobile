class AdministrationMarche {
  const AdministrationMarche({
    required this.id,
    required this.nom,
    required this.sigle,
    required this.typeEntite,
    required this.adresse,
    required this.telephone,
    required this.email,
    required this.actif,
    this.dateCreation,
    this.dateMaj,
    this.nombreUtilisateurs = 0,
    this.nombreAppelsOffres = 0,
    this.nombreContrats = 0,
  });

  final String id;
  final String nom;
  final String sigle;
  final String typeEntite;
  final String adresse;
  final String telephone;
  final String email;

  final bool actif;

  final DateTime? dateCreation;
  final DateTime? dateMaj;

  final int nombreUtilisateurs;
  final int nombreAppelsOffres;
  final int nombreContrats;

  factory AdministrationMarche.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdministrationMarche(
      id: _parseString(
        json['id'],
      ),
      nom: _parseString(
        json['nom'],
      ),
      sigle: _parseString(
        json['sigle'],
      ),
      typeEntite: _parseString(
        json['type_entite'],
      ),
      adresse: _parseString(
        json['adresse'],
      ),
      telephone: _parseString(
        json['telephone'],
      ),
      email: _parseString(
        json['email'],
      ),
      actif: _parseBool(
        json['actif'],
        valeurParDefaut: true,
      ),
      dateCreation: _parseDate(
        json['date_creation'],
      ),
      dateMaj: _parseDate(
        json['date_maj'],
      ),
      nombreUtilisateurs: _parseInt(
        json['nombre_utilisateurs'],
      ),
      nombreAppelsOffres: _parseInt(
        json['nombre_appels_offres'],
      ),
      nombreContrats: _parseInt(
        json['nombre_contrats'],
      ),
    );
  }

  AdministrationMarche copyWith({
    String? id,
    String? nom,
    String? sigle,
    String? typeEntite,
    String? adresse,
    String? telephone,
    String? email,
    bool? actif,
    DateTime? dateCreation,
    DateTime? dateMaj,
    int? nombreUtilisateurs,
    int? nombreAppelsOffres,
    int? nombreContrats,
  }) {
    return AdministrationMarche(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      sigle: sigle ?? this.sigle,
      typeEntite:
          typeEntite ?? this.typeEntite,
      adresse: adresse ?? this.adresse,
      telephone:
          telephone ?? this.telephone,
      email: email ?? this.email,
      actif: actif ?? this.actif,
      dateCreation:
          dateCreation ?? this.dateCreation,
      dateMaj: dateMaj ?? this.dateMaj,
      nombreUtilisateurs:
          nombreUtilisateurs ??
              this.nombreUtilisateurs,
      nombreAppelsOffres:
          nombreAppelsOffres ??
              this.nombreAppelsOffres,
      nombreContrats:
          nombreContrats ??
              this.nombreContrats,
    );
  }

  String get nomAffiche {
    final nomNettoye = nom.trim();
    final sigleNettoye = sigle.trim();

    if (nomNettoye.isEmpty &&
        sigleNettoye.isEmpty) {
      return 'Administration sans nom';
    }

    if (sigleNettoye.isEmpty) {
      return nomNettoye;
    }

    if (nomNettoye.isEmpty) {
      return sigleNettoye;
    }

    return '$nomNettoye ($sigleNettoye)';
  }

  String get typeEntiteFormate {
    final valeur = typeEntite
        .replaceAll('_', ' ')
        .trim();

    if (valeur.isEmpty) {
      return 'Non renseigné';
    }

    return valeur
        .split(' ')
        .where(
          (element) => element.isNotEmpty,
        )
        .map(
          (element) =>
              '${element[0].toUpperCase()}'
              '${element.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  bool get possedeCoordonnees =>
      adresse.trim().isNotEmpty ||
      telephone.trim().isNotEmpty ||
      email.trim().isNotEmpty;
}

class ListeAdministrationsResult {
  const ListeAdministrationsResult({
    required this.nombre,
    required this.administrations,
  });

  final int nombre;

  final List<AdministrationMarche>
      administrations;

  factory ListeAdministrationsResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final liste = json['administrations'];

    final administrations = liste is List
        ? liste
            .whereType<Map>()
            .map(
              (element) =>
                  AdministrationMarche.fromJson(
                Map<String, dynamic>.from(
                  element,
                ),
              ),
            )
            .where(
              (administration) =>
                  administration.id.isNotEmpty &&
                  administration.nom.isNotEmpty,
            )
            .toList()
        : <AdministrationMarche>[];

    return ListeAdministrationsResult(
      nombre: _parseInt(
        json['nombre'],
        valeurParDefaut:
            administrations.length,
      ),
      administrations: administrations,
    );
  }

  static const vide =
      ListeAdministrationsResult(
    nombre: 0,
    administrations: [],
  );
}

class DonneesAdministration {
  const DonneesAdministration({
    required this.nom,
    required this.sigle,
    required this.typeEntite,
    required this.adresse,
    required this.telephone,
    required this.email,
  });

  final String nom;
  final String sigle;
  final String typeEntite;
  final String adresse;
  final String telephone;
  final String email;

  Map<String, dynamic> versJson() {
    return {
      'nom': nom.trim(),
      'sigle': _nullableString(sigle),
      'type_entite':
          _nullableString(typeEntite),
      'adresse':
          _nullableString(adresse),
      'telephone':
          _nullableString(telephone),
      'email': _nullableString(
        email.toLowerCase(),
      ),
    };
  }
}

String _parseString(
  dynamic valeur,
) {
  return valeur?.toString().trim() ?? '';
}

String? _nullableString(
  String? valeur,
) {
  final texte = valeur?.trim() ?? '';

  return texte.isEmpty ? null : texte;
}

bool _parseBool(
  dynamic valeur, {
  bool valeurParDefaut = false,
}) {
  if (valeur == null) {
    return valeurParDefaut;
  }

  if (valeur is bool) {
    return valeur;
  }

  if (valeur is num) {
    return valeur != 0;
  }

  final texte = valeur
      .toString()
      .trim()
      .toLowerCase();

  if (texte == 'true' ||
      texte == '1' ||
      texte == 'oui') {
    return true;
  }

  if (texte == 'false' ||
      texte == '0' ||
      texte == 'non') {
    return false;
  }

  return valeurParDefaut;
}

int _parseInt(
  dynamic valeur, {
  int valeurParDefaut = 0,
}) {
  if (valeur == null) {
    return valeurParDefaut;
  }

  if (valeur is int) {
    return valeur;
  }

  if (valeur is num) {
    return valeur.toInt();
  }

  return int.tryParse(
        valeur.toString().trim(),
      ) ??
      valeurParDefaut;
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