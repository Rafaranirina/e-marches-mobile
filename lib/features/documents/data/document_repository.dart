import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'document_marche.dart';

class DocumentRepository {
  DocumentRepository({
    Dio? dio,
  }) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  static const Set<String> contextesAutorises = {
    'appel-offre',
    'soumission',
    'contrat',
  };

  Future<List<DocumentMarche>> lister({
    required String contexte,
    required String contexteId,
  }) async {
    final contexteNormalise =
        contexte.trim().toLowerCase();

    final contexteIdNormalise =
        contexteId.trim();

    _verifierContexte(
      contexteNormalise,
      contexteIdNormalise,
    );

    try {
      final response = await _dio.get(
        '/api/documents/'
        '$contexteNormalise/'
        '$contexteIdNormalise',
      );

      final data = _convertirReponse(
        response.data,
      );

      final liste = data['documents'];

      if (liste is! List) {
        throw const DocumentException(
          'La liste des documents est invalide.',
        );
      }

      return liste
          .whereType<Map>()
          .map(
            (item) => DocumentMarche.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where(
            (document) =>
                document.id.isNotEmpty &&
                document.nomFichier.isNotEmpty,
          )
          .toList();
    } on DocumentException {
      rethrow;
    } on DioException catch (error) {
      throw DocumentException(
        _extraireMessageErreur(
          error,
          'Impossible de récupérer les documents.',
        ),
      );
    } catch (_) {
      throw const DocumentException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  Future<UploadDocumentResult> uploader({
    required String cheminFichier,
    required String contexte,
    required String contexteId,
    String? typeDocument,
  }) async {
    final cheminNormalise =
        cheminFichier.trim();

    final contexteNormalise =
        contexte.trim().toLowerCase();

    final contexteIdNormalise =
        contexteId.trim();

    if (cheminNormalise.isEmpty) {
      throw const DocumentException(
        'Sélectionnez un fichier.',
      );
    }

    _verifierContexte(
      contexteNormalise,
      contexteIdNormalise,
    );

    final nomFichier = cheminNormalise
        .split(RegExp(r'[\\/]'))
        .last
        .trim();

    if (nomFichier.isEmpty) {
      throw const DocumentException(
        'Le nom du fichier est invalide.',
      );
    }

    try {
      final fichier =
          await MultipartFile.fromFile(
        cheminNormalise,
        filename: nomFichier,
      );

      final donnees = <String, dynamic>{
        'fichier': fichier,
        'type_document':
            _nullableString(typeDocument),
        _cleContexteApi(contexteNormalise):
            contexteIdNormalise,
      };

      final response = await _dio.post(
        '/api/documents',
        data: FormData.fromMap(donnees),
      );

      final data = _convertirReponse(
        response.data,
      );

      final documentData =
          data['document'];

      DocumentMarche? document;

      if (documentData is Map) {
        document = DocumentMarche.fromJson(
          Map<String, dynamic>.from(
            documentData,
          ),
        );
      }

      return UploadDocumentResult(
        message: _extraireMessageReponse(
          data,
          'Document téléversé avec succès.',
        ),
        document: document,
      );
    } on DocumentException {
      rethrow;
    } on DioException catch (error) {
      throw DocumentException(
        _extraireMessageErreur(
          error,
          'Impossible de téléverser le document.',
        ),
      );
    } catch (_) {
      throw const DocumentException(
        'Impossible de lire ou de téléverser le fichier.',
      );
    }
  }

  Future<TelechargementDocumentResult>
      obtenirLienTelechargement(
    String documentId,
  ) async {
    final documentIdNormalise =
        documentId.trim();

    if (documentIdNormalise.isEmpty) {
      throw const DocumentException(
        'L’identifiant du document est invalide.',
      );
    }

    try {
      final response = await _dio.get(
        '/api/documents/telecharger/'
        '$documentIdNormalise',
      );

      final data = _convertirReponse(
        response.data,
      );

      final url =
          data['url_telechargement']
                  ?.toString()
                  .trim() ??
              '';

      if (url.isEmpty) {
        throw const DocumentException(
          'Le lien de téléchargement est invalide.',
        );
      }

      return TelechargementDocumentResult(
        nomFichier:
            data['nom_fichier']
                    ?.toString()
                    .trim() ??
                '',
        urlTelechargement: url,
        expireDans:
            data['expire_dans']
                    ?.toString()
                    .trim() ??
                '',
      );
    } on DocumentException {
      rethrow;
    } on DioException catch (error) {
      throw DocumentException(
        _extraireMessageErreur(
          error,
          'Impossible de générer le lien de téléchargement.',
        ),
      );
    } catch (_) {
      throw const DocumentException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  void _verifierContexte(
    String contexte,
    String contexteId,
  ) {
    if (!contextesAutorises.contains(
      contexte,
    )) {
      throw const DocumentException(
        'Le contexte du document est invalide.',
      );
    }

    if (contexteId.isEmpty) {
      throw const DocumentException(
        'L’identifiant du contexte est invalide.',
      );
    }
  }

  String _cleContexteApi(
    String contexte,
  ) {
    switch (contexte) {
      case 'appel-offre':
        return 'appel_offre_id';

      case 'soumission':
        return 'soumission_id';

      case 'contrat':
        return 'contrat_id';

      default:
        throw const DocumentException(
          'Le contexte du document est invalide.',
        );
    }
  }

  Map<String, dynamic> _convertirReponse(
    dynamic responseData,
  ) {
    if (responseData is! Map) {
      throw const DocumentException(
        'Réponse invalide du serveur.',
      );
    }

    return Map<String, dynamic>.from(
      responseData,
    );
  }

  String _extraireMessageReponse(
    Map<String, dynamic> data,
    String messageParDefaut,
  ) {
    final message =
        data['message']?.toString().trim() ?? '';

    return message.isEmpty
        ? messageParDefaut
        : message;
  }

  String _extraireMessageErreur(
    DioException error,
    String messageParDefaut,
  ) {
    final responseData =
        error.response?.data;

    if (responseData is Map) {
      final message =
          responseData['message']
              ?.toString()
              .trim();

      if (message != null &&
          message.isNotEmpty) {
        return message;
      }
    }

    if (error.type ==
            DioExceptionType.connectionTimeout ||
        error.type ==
            DioExceptionType.receiveTimeout ||
        error.type ==
            DioExceptionType.sendTimeout) {
      return 'Le serveur met trop de temps à répondre.';
    }

    if (error.type ==
        DioExceptionType.connectionError) {
      return 'Connexion au serveur impossible.';
    }

    switch (error.response?.statusCode) {
      case 400:
        return 'Les informations ou le fichier transmis sont invalides.';

      case 401:
        return 'Votre session a expiré. Reconnectez-vous.';

      case 403:
        return 'Vous n’êtes pas autorisé à effectuer cette action.';

      case 404:
        return 'Le document est introuvable.';

      case 413:
        return 'Le fichier sélectionné est trop volumineux.';

      default:
        return messageParDefaut;
    }
  }

  static String? _nullableString(
    String? valeur,
  ) {
    final texte = valeur?.trim() ?? '';

    return texte.isEmpty ? null : texte;
  }
}

class UploadDocumentResult {
  const UploadDocumentResult({
    required this.message,
    this.document,
  });

  final String message;
  final DocumentMarche? document;
}

class TelechargementDocumentResult {
  const TelechargementDocumentResult({
    required this.nomFichier,
    required this.urlTelechargement,
    required this.expireDans,
  });

  final String nomFichier;
  final String urlTelechargement;
  final String expireDans;
}

class DocumentException implements Exception {
  const DocumentException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}