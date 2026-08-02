class AdministrationOption {
  const AdministrationOption({
    required this.id,
    required this.nom,
    this.sigle,
    this.typeEntite,
  });

  final String id;
  final String nom;
  final String? sigle;
  final String? typeEntite;

  String get libelle {
    final sigleNettoye = sigle?.trim() ?? '';

    if (sigleNettoye.isEmpty) {
      return nom;
    }

    return '$nom ($sigleNettoye)';
  }

  factory AdministrationOption.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdministrationOption(
      id: json['id']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      sigle: json['sigle']?.toString(),
      typeEntite: json['type_entite']?.toString(),
    );
  }
}

class CategorieOption {
  const CategorieOption({
    required this.id,
    required this.nom,
    this.description,
    this.categorieParentId,
  });

  final String id;
  final String nom;
  final String? description;
  final String? categorieParentId;

  factory CategorieOption.fromJson(
    Map<String, dynamic> json,
  ) {
    return CategorieOption(
      id: json['id']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      description: json['description']?.toString(),
      categorieParentId:
          json['categorie_parent_id']?.toString(),
    );
  }
}