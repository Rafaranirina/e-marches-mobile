/// Une entrée de l'historique des changements de statut d'un appel
/// d'offres (`GET /api/appels-offres/:id/historique`). `ancienStatut` est
/// `null` pour l'entrée de création initiale.
class AppelOffreHistorique {
  const AppelOffreHistorique({
    required this.id,
    required this.nouveauStatut,
    this.ancienStatut,
    this.motif,
    this.dateModification,
    this.modifieParNom,
    this.modifieParRole,
  });

  final String id;
  final String? ancienStatut;
  final String nouveauStatut;
  final String? motif;
  final DateTime? dateModification;
  final String? modifieParNom;
  final String? modifieParRole;

  factory AppelOffreHistorique.fromJson(
    Map<String, dynamic> json,
  ) {
    return AppelOffreHistorique(
      id: json['id']?.toString() ?? '',
      ancienStatut: _nullableString(
        json['ancien_statut'],
      ),
      nouveauStatut:
          json['nouveau_statut']?.toString() ??
              '',
      motif: _nullableString(json['motif']),
      dateModification: _parseDate(
        json['date_modification'],
      ),
      modifieParNom: _nomComplet(
        json['modifie_par_prenom'],
        json['modifie_par_nom'],
      ),
      modifieParRole: _nullableString(
        json['modifie_par_role'],
      ),
    );
  }

  static String? _nomComplet(
    dynamic prenom,
    dynamic nom,
  ) {
    final prenomTexte =
        prenom?.toString().trim() ?? '';

    final nomTexte =
        nom?.toString().trim() ?? '';

    final complet =
        [prenomTexte, nomTexte]
            .where((partie) => partie.isNotEmpty)
            .join(' ')
            .trim();

    return complet.isEmpty ? null : complet;
  }

  static String? _nullableString(
    dynamic value,
  ) {
    final texte = value?.toString().trim() ?? '';

    return texte.isEmpty ? null : texte;
  }

  static DateTime? _parseDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
