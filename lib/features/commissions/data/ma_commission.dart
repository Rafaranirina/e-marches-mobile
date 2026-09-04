/// Modèle représentant une commission dont l'utilisateur connecté (rôle
/// `commission`) est membre, tel que renvoyé par
/// `GET /api/commissions/mes-commissions`. Ce point d'accès renvoie, pour
/// chaque commission, l'appel d'offres concerné — une forme différente de
/// `Commission` (partagé avec `evaluations`), d'où ce petit type dédié plutôt
/// qu'une extension du modèle partagé.
class MaCommission {
  const MaCommission({
    required this.commissionId,
    required this.commissionNom,
    required this.appelOffreId,
    required this.appelOffreReference,
    required this.appelOffreTitre,
    this.fonction,
    this.dateCreation,
    this.appelOffreStatut,
    this.dateLimiteSoumission,
    this.dateOuverturePlis,
  });

  final String commissionId;
  final String commissionNom;
  final String? fonction;
  final DateTime? dateCreation;

  final String appelOffreId;
  final String appelOffreReference;
  final String appelOffreTitre;
  final String? appelOffreStatut;
  final DateTime? dateLimiteSoumission;
  final DateTime? dateOuverturePlis;

  String get fonctionAffichee {
    final valeur = fonction?.trim() ?? '';

    return valeur.isEmpty ? 'Membre' : valeur;
  }

  factory MaCommission.fromJson(
    Map<String, dynamic> json,
  ) {
    return MaCommission(
      commissionId: _parseString(json['id']),
      commissionNom: _parseString(json['nom']),
      fonction: _parseStringNullable(json['fonction']),
      dateCreation: _parseDate(json['date_creation']),
      appelOffreId: _parseString(json['appel_offre_id']),
      appelOffreReference: _parseString(
        json['appel_offre_reference'],
      ),
      appelOffreTitre: _parseString(
        json['appel_offre_titre'],
      ),
      appelOffreStatut: _parseStringNullable(
        json['appel_offre_statut'],
      ),
      dateLimiteSoumission: _parseDate(
        json['date_limite_soumission'],
      ),
      dateOuverturePlis: _parseDate(
        json['date_ouverture_plis'],
      ),
    );
  }
}

class ListeMesCommissionsResult {
  const ListeMesCommissionsResult({
    required this.nombre,
    required this.commissions,
  });

  final int nombre;
  final List<MaCommission> commissions;

  factory ListeMesCommissionsResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final liste = json['commissions'];

    final commissions = liste is List
        ? liste
            .whereType<Map>()
            .map(
              (element) => MaCommission.fromJson(
                Map<String, dynamic>.from(element),
              ),
            )
            .where(
              (commission) =>
                  commission.commissionId.isNotEmpty,
            )
            .toList()
        : <MaCommission>[];

    return ListeMesCommissionsResult(
      nombre: _parseInt(
        json['nombre'],
        valeurParDefaut: commissions.length,
      ),
      commissions: commissions,
    );
  }

  static const vide = ListeMesCommissionsResult(
    nombre: 0,
    commissions: [],
  );
}

String _parseString(dynamic valeur) {
  return valeur?.toString().trim() ?? '';
}

String? _parseStringNullable(dynamic valeur) {
  final texte = valeur?.toString().trim() ?? '';

  return texte.isEmpty ? null : texte;
}

DateTime? _parseDate(dynamic valeur) {
  final texte = valeur?.toString().trim() ?? '';

  if (texte.isEmpty) {
    return null;
  }

  return DateTime.tryParse(texte);
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
