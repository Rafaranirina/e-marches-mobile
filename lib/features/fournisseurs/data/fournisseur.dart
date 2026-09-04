class Fournisseur {
  const Fournisseur({
    required this.id,
    required this.raisonSociale,
    this.nif,
    this.stat,
    this.rcs,
    this.adresse,
    this.telephone,
    this.email,
    this.representantLegal,
    this.statutValidation,
    this.dateCreation,
    this.dateMaj,
    this.nombreUtilisateurs,
    this.nombreSoumissions,
    this.nombreContrats,
  });

  static const List<String> statutsAutorises = [
    'en_attente',
    'actif',
    'inactif',
    'suspendu',
  ];

  final String id;
  final String raisonSociale;
  final String? nif;
  final String? stat;
  final String? rcs;
  final String? adresse;
  final String? telephone;
  final String? email;
  final String? representantLegal;
  final String? statutValidation;

  final DateTime? dateCreation;
  final DateTime? dateMaj;

  final int? nombreUtilisateurs;
  final int? nombreSoumissions;
  final int? nombreContrats;

  factory Fournisseur.fromJson(
    Map<String, dynamic> json,
  ) {
    return Fournisseur(
      id: _parseString(
        json['id'],
      ),
      raisonSociale: _parseString(
        json['raison_sociale'],
      ),
      nif: _parseStringNullable(
        json['nif'],
      ),
      stat: _parseStringNullable(
        json['stat'],
      ),
      rcs: _parseStringNullable(
        json['rcs'],
      ),
      adresse: _parseStringNullable(
        json['adresse'],
      ),
      telephone: _parseStringNullable(
        json['telephone'],
      ),
      email: _parseStringNullable(
        json['email'],
      ),
      representantLegal:
          _parseStringNullable(
        json['representant_legal'],
      ),
      statutValidation:
          _parseStringNullable(
        json['statut_validation'],
      ),
      dateCreation: _parseDate(
        json['date_creation'],
      ),
      dateMaj: _parseDate(
        json['date_maj'],
      ),
      nombreUtilisateurs:
          _parseIntNullable(
        json['nombre_utilisateurs'],
      ),
      nombreSoumissions:
          _parseIntNullable(
        json['nombre_soumissions'],
      ),
      nombreContrats:
          _parseIntNullable(
        json['nombre_contrats'],
      ),
    );
  }

  Fournisseur copyWith({
    String? id,
    String? raisonSociale,
    String? nif,
    String? stat,
    String? rcs,
    String? adresse,
    String? telephone,
    String? email,
    String? representantLegal,
    String? statutValidation,
    DateTime? dateCreation,
    DateTime? dateMaj,
    int? nombreUtilisateurs,
    int? nombreSoumissions,
    int? nombreContrats,
  }) {
    return Fournisseur(
      id: id ?? this.id,
      raisonSociale:
          raisonSociale ?? this.raisonSociale,
      nif: nif ?? this.nif,
      stat: stat ?? this.stat,
      rcs: rcs ?? this.rcs,
      adresse: adresse ?? this.adresse,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      representantLegal:
          representantLegal ??
              this.representantLegal,
      statutValidation:
          statutValidation ??
              this.statutValidation,
      dateCreation:
          dateCreation ?? this.dateCreation,
      dateMaj: dateMaj ?? this.dateMaj,
      nombreUtilisateurs:
          nombreUtilisateurs ??
              this.nombreUtilisateurs,
      nombreSoumissions:
          nombreSoumissions ??
              this.nombreSoumissions,
      nombreContrats:
          nombreContrats ??
              this.nombreContrats,
    );
  }

  bool get estActif =>
      statutValidation
          ?.trim()
          .toLowerCase() ==
      'actif';

  bool get estEnAttente =>
      statutValidation
          ?.trim()
          .toLowerCase() ==
      'en_attente';

  bool get estInactif =>
      statutValidation
          ?.trim()
          .toLowerCase() ==
      'inactif';

  bool get estSuspendu =>
      statutValidation
          ?.trim()
          .toLowerCase() ==
      'suspendu';

  String get statutFormate =>
      formaterStatutFournisseur(
        statutValidation,
      );
}

/// Une entrée de l'historique des changements de statut d'une
/// entreprise (`historique_statuts_entreprises`, exposé par
/// `GET /api/entreprises/:id/historique`, réservé à
/// `admin_national`).
class HistoriqueStatutFournisseur {
  const HistoriqueStatutFournisseur({
    required this.id,
    required this.entrepriseId,
    this.ancienStatut,
    required this.nouveauStatut,
    this.motif,
    this.dateModification,
    required this.modifieParId,
    required this.modifieParNom,
    required this.modifieParPrenom,
    required this.modifieParEmail,
    required this.modifieParRole,
  });

  final String id;
  final String entrepriseId;
  final String? ancienStatut;
  final String nouveauStatut;
  final String? motif;
  final DateTime? dateModification;

  final String modifieParId;
  final String modifieParNom;
  final String modifieParPrenom;
  final String modifieParEmail;
  final String modifieParRole;

  factory HistoriqueStatutFournisseur.fromJson(
    Map<String, dynamic> json,
  ) {
    return HistoriqueStatutFournisseur(
      id: _parseString(
        json['id'],
      ),
      entrepriseId: _parseString(
        json['entreprise_id'],
      ),
      ancienStatut: _parseStringNullable(
        json['ancien_statut'],
      ),
      nouveauStatut: _parseString(
        json['nouveau_statut'],
      ),
      motif: _parseStringNullable(
        json['motif'],
      ),
      dateModification: _parseDate(
        json['date_modification'],
      ),
      modifieParId: _parseString(
        json['modifie_par_id'],
      ),
      modifieParNom: _parseString(
        json['modifie_par_nom'],
      ),
      modifieParPrenom: _parseString(
        json['modifie_par_prenom'],
      ),
      modifieParEmail: _parseString(
        json['modifie_par_email'],
      ),
      modifieParRole: _parseString(
        json['modifie_par_role'],
      ),
    );
  }

  String get modifieParNomComplet {
    final morceaux = [
      modifieParPrenom.trim(),
      modifieParNom.trim(),
    ].where(
      (element) => element.isNotEmpty,
    );

    final valeur = morceaux.join(' ');

    return valeur.isEmpty
        ? modifieParEmail
        : valeur;
  }

  String get ancienStatutFormate =>
      formaterStatutFournisseur(
        ancienStatut,
      );

  String get nouveauStatutFormate =>
      formaterStatutFournisseur(
        nouveauStatut,
      );
}

/// Données envoyées à `POST /api/entreprises` pour la création
/// manuelle d'un fournisseur par l'administrateur national. Seule la
/// raison sociale est obligatoire côté backend.
class DonneesCreationFournisseur {
  const DonneesCreationFournisseur({
    required this.raisonSociale,
    this.nif,
    this.stat,
    this.rcs,
    this.adresse,
    this.telephone,
    this.email,
    this.representantLegal,
  });

  final String raisonSociale;
  final String? nif;
  final String? stat;
  final String? rcs;
  final String? adresse;
  final String? telephone;
  final String? email;
  final String? representantLegal;

  Map<String, dynamic> versJson() {
    return {
      'raison_sociale':
          raisonSociale.trim(),
      'nif': _nullableString(nif),
      'stat': _nullableString(stat),
      'rcs': _nullableString(rcs),
      'adresse': _nullableString(adresse),
      'telephone':
          _nullableString(telephone),
      'email': _nullableString(
        email?.toLowerCase(),
      ),
      'representant_legal':
          _nullableString(
        representantLegal,
      ),
    };
  }
}

/// Données envoyées à `PUT /api/entreprises/:id` par
/// l'administrateur national. Le formulaire mobile ne permet de
/// modifier que les coordonnées de l'entreprise (adresse, téléphone,
/// e-mail, représentant légal) — la raison sociale et les
/// identifiants légaux (NIF/STAT/RCS) restent figés après la
/// création.
class DonneesModificationFournisseur {
  const DonneesModificationFournisseur({
    this.adresse,
    this.telephone,
    this.email,
    this.representantLegal,
  });

  final String? adresse;
  final String? telephone;
  final String? email;
  final String? representantLegal;

  Map<String, dynamic> versJson() {
    return {
      'adresse': _nullableString(adresse),
      'telephone':
          _nullableString(telephone),
      'email': _nullableString(
        email?.toLowerCase(),
      ),
      'representant_legal':
          _nullableString(
        representantLegal,
      ),
    };
  }
}

String formaterStatutFournisseur(
  String? statut,
) {
  switch (statut?.trim().toLowerCase()) {
    case 'en_attente':
      return 'En attente';

    case 'actif':
      return 'Actif';

    case 'inactif':
      return 'Inactif';

    case 'suspendu':
      return 'Suspendu';

    default:
      final valeur = (statut ?? '')
          .replaceAll('_', ' ')
          .trim();

      return valeur.isEmpty
          ? 'Non défini'
          : valeur;
  }
}

String _parseString(
  dynamic valeur, {
  String valeurParDefaut = '',
}) {
  final texte =
      valeur?.toString().trim() ?? '';

  return texte.isEmpty
      ? valeurParDefaut
      : texte;
}

String? _parseStringNullable(
  dynamic valeur,
) {
  final texte =
      valeur?.toString().trim() ?? '';

  return texte.isEmpty ? null : texte;
}

String? _nullableString(
  String? valeur,
) {
  final texte = valeur?.trim() ?? '';

  return texte.isEmpty ? null : texte;
}

int? _parseIntNullable(
  dynamic valeur,
) {
  if (valeur == null) {
    return null;
  }

  if (valeur is int) {
    return valeur;
  }

  if (valeur is num) {
    return valeur.toInt();
  }

  final texte = valeur.toString().trim();

  if (texte.isEmpty) {
    return null;
  }

  return int.tryParse(texte) ??
      double.tryParse(texte)?.toInt();
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
