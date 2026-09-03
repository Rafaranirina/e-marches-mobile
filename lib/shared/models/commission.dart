/// Modèle partagé entre les features `commissions` et `evaluations`, qui
/// consomment toutes deux `GET /api/commissions/appel-offre/:appelOffreId`
/// et `POST /api/commissions/:id/membres` — avant cette unification, chaque
/// feature définissait sa propre copie divergente (`CommissionMarche` vs
/// `CommissionOption`, `MembreCommission` avec des champs différents selon
/// la feature), ce qui aurait fini par diverger silencieusement.
class MembreCommission {
  const MembreCommission({
    required this.utilisateurId,
    this.fonction,
    this.id,
    this.commissionId,
    this.dateCreation,
  });

  final String? id;
  final String? commissionId;

  final String utilisateurId;
  final String? fonction;

  final DateTime? dateCreation;

  factory MembreCommission.fromJson(
    Map<String, dynamic> json,
  ) {
    return MembreCommission(
      id: _parseStringNullable(json['id']),
      commissionId: _parseStringNullable(
        json['commission_id'],
      ),
      utilisateurId: _parseString(
        json['utilisateur_id'],
      ),
      fonction: _parseStringNullable(
        json['fonction'],
      ),
      dateCreation: _parseDate(
        json['date_creation'],
      ),
    );
  }

  MembreCommission copyWith({
    String? id,
    String? commissionId,
    String? utilisateurId,
    String? fonction,
    DateTime? dateCreation,
  }) {
    return MembreCommission(
      id: id ?? this.id,
      commissionId: commissionId ?? this.commissionId,
      utilisateurId: utilisateurId ?? this.utilisateurId,
      fonction: fonction ?? this.fonction,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }

  String get fonctionAffichee {
    final valeur = fonction?.trim() ?? '';

    return valeur.isEmpty ? 'Membre' : valeur;
  }
}

class Commission {
  const Commission({
    required this.id,
    required this.nom,
    this.appelOffreId,
    this.membres = const [],
    this.dateCreation,
    this.dateMaj,
  });

  final String id;
  final String nom;
  final String? appelOffreId;

  final List<MembreCommission> membres;

  final DateTime? dateCreation;
  final DateTime? dateMaj;

  factory Commission.fromJson(
    Map<String, dynamic> json,
  ) {
    final membresJson = json['membres'];

    final membres = membresJson is List
        ? membresJson
            .whereType<Map>()
            .map(
              (element) => MembreCommission.fromJson(
                Map<String, dynamic>.from(element),
              ),
            )
            .where(
              (membre) => membre.utilisateurId.isNotEmpty,
            )
            .toList()
        : <MembreCommission>[];

    return Commission(
      id: _parseString(json['id']),
      nom: _parseString(json['nom']),
      appelOffreId: _parseStringNullable(
        json['appel_offre_id'],
      ),
      membres: membres,
      dateCreation: _parseDate(json['date_creation']),
      dateMaj: _parseDate(json['date_maj']),
    );
  }

  Commission copyWith({
    String? id,
    String? nom,
    String? appelOffreId,
    List<MembreCommission>? membres,
    DateTime? dateCreation,
    DateTime? dateMaj,
  }) {
    return Commission(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      appelOffreId: appelOffreId ?? this.appelOffreId,
      membres: membres ?? this.membres,
      dateCreation: dateCreation ?? this.dateCreation,
      dateMaj: dateMaj ?? this.dateMaj,
    );
  }

  int get nombreMembres => membres.length;

  bool get possedeMembres => membres.isNotEmpty;

  bool contientUtilisateur(String utilisateurId) {
    final id = utilisateurId.trim();

    if (id.isEmpty) {
      return false;
    }

    return membres.any(
      (membre) => membre.utilisateurId == id,
    );
  }
}

class ListeCommissionsResult {
  const ListeCommissionsResult({
    required this.nombre,
    required this.commissions,
  });

  final int nombre;
  final List<Commission> commissions;

  factory ListeCommissionsResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final liste = json['commissions'];

    final commissions = liste is List
        ? liste
            .whereType<Map>()
            .map(
              (element) => Commission.fromJson(
                Map<String, dynamic>.from(element),
              ),
            )
            .where(
              (commission) =>
                  commission.id.isNotEmpty &&
                  commission.nom.isNotEmpty,
            )
            .toList()
        : <Commission>[];

    return ListeCommissionsResult(
      nombre: _parseInt(
        json['nombre'],
        valeurParDefaut: commissions.length,
      ),
      commissions: commissions,
    );
  }

  static const vide = ListeCommissionsResult(
    nombre: 0,
    commissions: [],
  );
}

class DonneesCommission {
  const DonneesCommission({
    required this.nom,
    required this.appelOffreId,
  });

  final String nom;
  final String appelOffreId;

  Map<String, dynamic> versJson() {
    return {
      'nom': nom.trim(),
      'appel_offre_id': appelOffreId.trim(),
    };
  }
}

class DonneesMembreCommission {
  const DonneesMembreCommission({
    required this.utilisateurId,
    required this.fonction,
  });

  final String utilisateurId;
  final String fonction;

  Map<String, dynamic> versJson() {
    return {
      'utilisateur_id': utilisateurId.trim(),
      'fonction': _nullableString(fonction),
    };
  }
}

String _parseString(dynamic valeur) {
  return valeur?.toString().trim() ?? '';
}

String? _parseStringNullable(dynamic valeur) {
  final texte = valeur?.toString().trim() ?? '';

  return texte.isEmpty ? null : texte;
}

String? _nullableString(String? valeur) {
  final texte = valeur?.trim() ?? '';

  return texte.isEmpty ? null : texte;
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

  final texte = valeur.toString().trim();

  return int.tryParse(texte) ??
      double.tryParse(texte)?.toInt() ??
      valeurParDefaut;
}

DateTime? _parseDate(dynamic valeur) {
  final texte = valeur?.toString().trim() ?? '';

  if (texte.isEmpty) {
    return null;
  }

  return DateTime.tryParse(texte);
}
