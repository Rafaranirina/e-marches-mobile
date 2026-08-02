class UtilisateurGestion {
  const UtilisateurGestion({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.role,
    required this.statut,
    required this.doubleAuthActive,
    this.administrationId,
    this.entrepriseId,
    this.derniereConnexion,
    this.dateCreation,
    this.dateMaj,
  });

  static const List<String> rolesAutorises = [
    'admin_national',
    'administration',
    'fournisseur',
    'commission',
  ];

  static const List<String> statutsAutorises = [
    'en_attente',
    'actif',
    'inactif',
    'suspendu',
  ];

  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String role;
  final String statut;

  final String? administrationId;
  final String? entrepriseId;

  final bool doubleAuthActive;

  final DateTime? derniereConnexion;
  final DateTime? dateCreation;
  final DateTime? dateMaj;

  factory UtilisateurGestion.fromJson(
    Map<String, dynamic> json,
  ) {
    return UtilisateurGestion(
      id: _parseString(
        json['id'],
      ),
      nom: _parseString(
        json['nom'],
      ),
      prenom: _parseString(
        json['prenom'],
      ),
      email: _parseString(
        json['email'],
      ),
      telephone: _parseString(
        json['telephone'],
      ),
      role: _parseString(
        json['role'],
      ),
      statut: _parseString(
        json['statut'],
        valeurParDefaut: 'en_attente',
      ),
      administrationId:
          _parseStringNullable(
        json['administration_id'],
      ),
      entrepriseId:
          _parseStringNullable(
        json['entreprise_id'],
      ),
      doubleAuthActive: _parseBool(
        json['double_auth_active'],
      ),
      derniereConnexion: _parseDate(
        json['derniere_connexion'],
      ),
      dateCreation: _parseDate(
        json['date_creation'],
      ),
      dateMaj: _parseDate(
        json['date_maj'],
      ),
    );
  }

  UtilisateurGestion copyWith({
    String? id,
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? role,
    String? statut,
    String? administrationId,
    String? entrepriseId,
    bool? doubleAuthActive,
    DateTime? derniereConnexion,
    DateTime? dateCreation,
    DateTime? dateMaj,
  }) {
    return UtilisateurGestion(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      telephone:
          telephone ?? this.telephone,
      role: role ?? this.role,
      statut: statut ?? this.statut,
      administrationId:
          administrationId ??
              this.administrationId,
      entrepriseId:
          entrepriseId ??
              this.entrepriseId,
      doubleAuthActive:
          doubleAuthActive ??
              this.doubleAuthActive,
      derniereConnexion:
          derniereConnexion ??
              this.derniereConnexion,
      dateCreation:
          dateCreation ??
              this.dateCreation,
      dateMaj: dateMaj ?? this.dateMaj,
    );
  }

  String get nomComplet {
    final morceaux = [
      prenom.trim(),
      nom.trim(),
    ].where(
      (element) => element.isNotEmpty,
    );

    final valeur = morceaux.join(' ');

    return valeur.isEmpty
        ? email
        : valeur;
  }

  bool get estActif =>
      statut.trim().toLowerCase() ==
      'actif';

  bool get estEnAttente =>
      statut.trim().toLowerCase() ==
      'en_attente';

  bool get estInactif =>
      statut.trim().toLowerCase() ==
      'inactif';

  bool get estSuspendu =>
      statut.trim().toLowerCase() ==
      'suspendu';

  bool get estAdministrateurNational =>
      role.trim().toLowerCase() ==
      'admin_national';

  bool get estAdministration =>
      role.trim().toLowerCase() ==
      'administration';

  bool get estFournisseur =>
      role.trim().toLowerCase() ==
      'fournisseur';

  bool get estCommission =>
      role.trim().toLowerCase() ==
      'commission';

  String get roleFormate {
    switch (role.trim().toLowerCase()) {
      case 'admin_national':
        return 'Administrateur national';

      case 'administration':
        return 'Administration';

      case 'fournisseur':
        return 'Fournisseur';

      case 'commission':
        return 'Commission';

      default:
        final valeur = role
            .replaceAll('_', ' ')
            .trim();

        return valeur.isEmpty
            ? 'Non défini'
            : valeur;
    }
  }

  String get statutFormate {
    switch (statut.trim().toLowerCase()) {
      case 'en_attente':
        return 'En attente';

      case 'actif':
        return 'Actif';

      case 'inactif':
        return 'Inactif';

      case 'suspendu':
        return 'Suspendu';

      default:
        final valeur = statut
            .replaceAll('_', ' ')
            .trim();

        return valeur.isEmpty
            ? 'Non défini'
            : valeur;
    }
  }
}

class ListeUtilisateursResult {
  const ListeUtilisateursResult({
    required this.total,
    required this.utilisateurs,
  });

  final int total;
  final List<UtilisateurGestion>
      utilisateurs;

  factory ListeUtilisateursResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final liste = json['utilisateurs'];

    final utilisateurs = liste is List
        ? liste
            .whereType<Map>()
            .map(
              (element) =>
                  UtilisateurGestion.fromJson(
                Map<String, dynamic>.from(
                  element,
                ),
              ),
            )
            .where(
              (utilisateur) =>
                  utilisateur.id.isNotEmpty &&
                  utilisateur.email.isNotEmpty,
            )
            .toList()
        : <UtilisateurGestion>[];

    return ListeUtilisateursResult(
      total: _parseInt(
        json['total'],
        valeurParDefaut:
            utilisateurs.length,
      ),
      utilisateurs: utilisateurs,
    );
  }

  static const vide =
      ListeUtilisateursResult(
    total: 0,
    utilisateurs: [],
  );
}

class DonneesUtilisateur {
  const DonneesUtilisateur({
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.role,
    required this.statut,
    required this.administrationId,
    required this.entrepriseId,
    this.motDePasse,
  });

  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String role;
  final String statut;

  final String? administrationId;
  final String? entrepriseId;
  final String? motDePasse;

  Map<String, dynamic> versJsonCreation() {
    return {
      'nom': nom.trim(),
      'prenom': _nullableString(prenom),
      'email':
          email.trim().toLowerCase(),
      'mot_de_passe':
          motDePasse?.trim(),
      'telephone':
          _nullableString(telephone),
      'role': role.trim(),
      'statut': statut.trim(),
      'administration_id':
          _nullableString(
        administrationId,
      ),
      'entreprise_id':
          _nullableString(
        entrepriseId,
      ),
    };
  }

  Map<String, dynamic>
      versJsonModification() {
    return {
      'nom': nom.trim(),
      'prenom': _nullableString(prenom),
      'email':
          email.trim().toLowerCase(),
      'telephone':
          _nullableString(telephone),
      'role': role.trim(),
      'administration_id':
          _nullableString(
        administrationId,
      ),
      'entreprise_id':
          _nullableString(
        entrepriseId,
      ),
    };
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

  return texte.isEmpty
      ? null
      : texte;
}

String? _nullableString(
  String? valeur,
) {
  final texte =
      valeur?.trim() ?? '';

  return texte.isEmpty
      ? null
      : texte;
}

bool _parseBool(
  dynamic valeur,
) {
  if (valeur is bool) {
    return valeur;
  }

  if (valeur is num) {
    return valeur != 0;
  }

  final texte = valeur
      ?.toString()
      .trim()
      .toLowerCase();

  return texte == 'true' ||
      texte == '1' ||
      texte == 'oui';
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

  final texte =
      valeur.toString().trim();

  if (texte.isEmpty) {
    return valeurParDefaut;
  }

  return int.tryParse(texte) ??
      double.tryParse(texte)?.toInt() ??
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