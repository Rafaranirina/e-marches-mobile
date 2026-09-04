class CategorieMarche {
  const CategorieMarche({
    required this.id,
    required this.nom,
    required this.description,
    this.categorieParentId,
    this.categorieParentNom,
    this.categorieParentActif,
    this.actif = true,
    this.dateCreation,
    this.dateMaj,
    this.nombreSousCategories = 0,
    this.nombreAppelsOffres = 0,
  });

  final String id;
  final String nom;
  final String description;
  final String? categorieParentId;
  final String? categorieParentNom;
  final bool? categorieParentActif;

  final bool actif;

  final DateTime? dateCreation;
  final DateTime? dateMaj;

  final int nombreSousCategories;
  final int nombreAppelsOffres;

  factory CategorieMarche.fromJson(
    Map<String, dynamic> json,
  ) {
    return CategorieMarche(
      id: _parseString(
        json['id'],
      ),
      nom: _parseString(
        json['nom'],
      ),
      description: _parseString(
        json['description'],
      ),
      categorieParentId:
          _parseStringNullable(
        json['categorie_parent_id'],
      ),
      categorieParentNom:
          _parseStringNullable(
        json['categorie_parent_nom'],
      ),
      categorieParentActif:
          _parseBoolNullable(
        json['categorie_parent_active'],
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
      nombreSousCategories: _parseInt(
        json['nombre_sous_categories'],
      ),
      nombreAppelsOffres: _parseInt(
        json['nombre_appels_offres'],
      ),
    );
  }

  CategorieMarche copyWith({
    String? id,
    String? nom,
    String? description,
    String? categorieParentId,
    String? categorieParentNom,
    bool? categorieParentActif,
    bool supprimerCategorieParent = false,
    bool? actif,
    DateTime? dateCreation,
    DateTime? dateMaj,
    int? nombreSousCategories,
    int? nombreAppelsOffres,
  }) {
    return CategorieMarche(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description:
          description ?? this.description,
      categorieParentId:
          supprimerCategorieParent
              ? null
              : categorieParentId ??
                  this.categorieParentId,
      categorieParentNom:
          supprimerCategorieParent
              ? null
              : categorieParentNom ??
                  this.categorieParentNom,
      categorieParentActif:
          supprimerCategorieParent
              ? null
              : categorieParentActif ??
                  this.categorieParentActif,
      actif: actif ?? this.actif,
      dateCreation:
          dateCreation ?? this.dateCreation,
      dateMaj: dateMaj ?? this.dateMaj,
      nombreSousCategories:
          nombreSousCategories ??
              this.nombreSousCategories,
      nombreAppelsOffres:
          nombreAppelsOffres ??
              this.nombreAppelsOffres,
    );
  }

  bool get estCategoriePrincipale {
    return categorieParentId == null ||
        categorieParentId!.trim().isEmpty;
  }

  bool get estSousCategorie {
    return !estCategoriePrincipale;
  }

  bool get estActive => actif;

  bool get estInactive => !actif;

  String get statutFormate =>
      actif ? 'Active' : 'Inactive';

  String get descriptionAffichee {
    final texte = description.trim();

    return texte.isEmpty
        ? 'Aucune description'
        : texte;
  }

  String get categorieParenteAffichee {
    final nom =
        categorieParentNom?.trim() ?? '';

    return nom.isEmpty
        ? 'Aucune — catégorie principale'
        : nom;
  }
}

class ListeCategoriesResult {
  const ListeCategoriesResult({
    required this.nombre,
    required this.categories,
  });

  final int nombre;
  final List<CategorieMarche> categories;

  factory ListeCategoriesResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final liste = json['categories'];

    final categories = liste is List
        ? liste
            .whereType<Map>()
            .map(
              (element) =>
                  CategorieMarche.fromJson(
                Map<String, dynamic>.from(
                  element,
                ),
              ),
            )
            .where(
              (categorie) =>
                  categorie.id.isNotEmpty &&
                  categorie.nom.isNotEmpty,
            )
            .toList()
        : <CategorieMarche>[];

    return ListeCategoriesResult(
      nombre: _parseInt(
        json['nombre'],
        valeurParDefaut:
            categories.length,
      ),
      categories: categories,
    );
  }

  static const vide =
      ListeCategoriesResult(
    nombre: 0,
    categories: [],
  );
}

class DonneesCategorie {
  const DonneesCategorie({
    required this.nom,
    required this.description,
    this.categorieParentId,
  });

  final String nom;
  final String description;
  final String? categorieParentId;

  Map<String, dynamic> versJson() {
    return {
      'nom': nom.trim(),
      'description':
          _nullableString(description),
      'categorie_parent_id':
          _nullableString(
        categorieParentId,
      ),
    };
  }
}

String _parseString(
  dynamic valeur,
) {
  return valeur?.toString().trim() ?? '';
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

  if (texte.isEmpty) {
    return valeurParDefaut;
  }

  return texte == 'true' ||
      texte == '1' ||
      texte == 'oui';
}

bool? _parseBoolNullable(
  dynamic valeur,
) {
  if (valeur == null) {
    return null;
  }

  return _parseBool(valeur);
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
