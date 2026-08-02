class CategorieMarche {
  const CategorieMarche({
    required this.id,
    required this.nom,
    required this.description,
    this.categorieParentId,
  });

  final String id;
  final String nom;
  final String description;
  final String? categorieParentId;

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
    );
  }

  CategorieMarche copyWith({
    String? id,
    String? nom,
    String? description,
    String? categorieParentId,
    bool supprimerCategorieParent = false,
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
    );
  }

  bool get estCategoriePrincipale {
    return categorieParentId == null ||
        categorieParentId!.trim().isEmpty;
  }

  bool get estSousCategorie {
    return !estCategoriePrincipale;
  }

  String get descriptionAffichee {
    final texte = description.trim();

    return texte.isEmpty
        ? 'Aucune description'
        : texte;
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