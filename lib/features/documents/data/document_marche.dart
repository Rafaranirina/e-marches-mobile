class DocumentMarche {
  const DocumentMarche({
    required this.id,
    required this.nomFichier,
    this.typeMime,
    this.tailleOctets,
    this.typeDocument,
    this.dateUpload,
  });

  final String id;
  final String nomFichier;
  final String? typeMime;
  final int? tailleOctets;
  final String? typeDocument;
  final DateTime? dateUpload;

  factory DocumentMarche.fromJson(
    Map<String, dynamic> json,
  ) {
    return DocumentMarche(
      id: json['id']?.toString() ?? '',
      nomFichier:
          json['nom_fichier']?.toString() ?? '',
      typeMime: _nullableString(
        json['type_mime'],
      ),
      tailleOctets: _parseInt(
        json['taille_octets'],
      ),
      typeDocument: _nullableString(
        json['type_document'],
      ),
      dateUpload: _parseDate(
        json['date_upload'],
      ),
    );
  }

  String get extension {
    final nom = nomFichier.trim();

    if (!nom.contains('.')) {
      return '';
    }

    return nom
        .split('.')
        .last
        .trim()
        .toLowerCase();
  }

  bool get estPdf =>
      typeMime?.toLowerCase() ==
          'application/pdf' ||
      extension == 'pdf';

  bool get estImage =>
      typeMime
          ?.toLowerCase()
          .startsWith('image/') ==
      true;

  bool get estDocumentWord =>
      extension == 'doc' ||
      extension == 'docx';

  bool get estTableur =>
      extension == 'xls' ||
      extension == 'xlsx' ||
      extension == 'csv';

  String get tailleFormatee {
    final taille = tailleOctets;

    if (taille == null || taille < 0) {
      return 'Taille non renseignée';
    }

    if (taille < 1024) {
      return '$taille octets';
    }

    final kiloOctets = taille / 1024;

    if (kiloOctets < 1024) {
      return '${kiloOctets.toStringAsFixed(1)} Ko';
    }

    final megaOctets = kiloOctets / 1024;

    if (megaOctets < 1024) {
      return '${megaOctets.toStringAsFixed(1)} Mo';
    }

    final gigaOctets = megaOctets / 1024;

    return '${gigaOctets.toStringAsFixed(1)} Go';
  }

  static String? _nullableString(
    dynamic value,
  ) {
    final texte =
        value?.toString().trim() ?? '';

    return texte.isEmpty ? null : texte;
  }

  static int? _parseInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    final texte =
        value.toString().trim();

    if (texte.isEmpty) {
      return null;
    }

    return int.tryParse(texte);
  }

  static DateTime? _parseDate(
    dynamic value,
  ) {
    final texte =
        value?.toString().trim() ?? '';

    if (texte.isEmpty) {
      return null;
    }

    return DateTime.tryParse(texte);
  }
}