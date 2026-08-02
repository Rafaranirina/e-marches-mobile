import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'soumission.dart';

class SoumissionRepository {
  SoumissionRepository({
    Dio? dio,
  }) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<List<Soumission>> listerParAppelOffre(
    String appelOffreId,
  ) async {
    try {
      final response = await _dio.get(
        '/api/soumissions/appel-offre/$appelOffreId',
      );

      final data = _convertirReponse(response.data);
      final liste = data['soumissions'];

      if (liste is! List) {
        throw const SoumissionException(
          'La liste des soumissions est invalide.',
        );
      }

      return liste
          .whereType<Map>()
          .map(
            (item) => Soumission.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where(
            (soumission) =>
                soumission.id.isNotEmpty &&
                soumission.reference.isNotEmpty,
          )
          .toList();
    } on SoumissionException {
      rethrow;
    } on DioException catch (error) {
      throw SoumissionException(
        _extraireMessageErreur(
          error,
          'Impossible de récupérer les soumissions.',
        ),
      );
    } catch (_) {
      throw const SoumissionException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  Future<SoumissionActionResult> deposer({
    required String reference,
    required String appelOffreId,
    required String entrepriseId,
    required double montantPropose,
    String? delaiExecution,
  }) async {
    try {
      final response = await _dio.post(
        '/api/soumissions',
        data: {
          'reference': reference.trim(),
          'appel_offre_id': appelOffreId.trim(),
          'entreprise_id': entrepriseId.trim(),
          'montant_propose': montantPropose,
          'delai_execution':
              _nullableString(delaiExecution),
        },
      );

      return _convertirResultatAction(response.data);
    } on SoumissionException {
      rethrow;
    } on DioException catch (error) {
      throw SoumissionException(
        _extraireMessageErreur(
          error,
          'Impossible de déposer la soumission.',
        ),
      );
    } catch (_) {
      throw const SoumissionException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  Future<SoumissionActionResult> valider({
    required String soumissionId,
    required String statut,
  }) async {
    final statutNormalise =
        statut.trim().toLowerCase();

    if (statutNormalise != 'recevable' &&
        statutNormalise != 'irrecevable') {
      throw const SoumissionException(
        'Le statut doit être recevable ou irrecevable.',
      );
    }

    try {
      final response = await _dio.patch(
        '/api/soumissions/$soumissionId/valider',
        data: {
          'statut': statutNormalise,
        },
      );

      return _convertirResultatAction(response.data);
    } on SoumissionException {
      rethrow;
    } on DioException catch (error) {
      throw SoumissionException(
        _extraireMessageErreur(
          error,
          'Impossible de valider la soumission.',
        ),
      );
    } catch (_) {
      throw const SoumissionException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  SoumissionActionResult _convertirResultatAction(
    dynamic responseData,
  ) {
    final data = _convertirReponse(responseData);
    final soumissionJson = data['soumission'];

    return SoumissionActionResult(
      message: data['message']?.toString() ??
          'Opération réalisée avec succès.',
      soumission: soumissionJson is Map
          ? Soumission.fromJson(
              Map<String, dynamic>.from(
                soumissionJson,
              ),
            )
          : null,
    );
  }

  Map<String, dynamic> _convertirReponse(
    dynamic responseData,
  ) {
    if (responseData is! Map) {
      throw const SoumissionException(
        'Réponse invalide du serveur.',
      );
    }

    return Map<String, dynamic>.from(responseData);
  }

  String _extraireMessageErreur(
    DioException error,
    String messageParDefaut,
  ) {
    final responseData = error.response?.data;

    if (responseData is Map) {
      final message =
          responseData['message']?.toString().trim();

      if (message != null && message.isNotEmpty) {
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

    if (error.response?.statusCode == 401) {
      return 'Votre session a expiré. Reconnectez-vous.';
    }

    if (error.response?.statusCode == 403) {
      return 'Vous n’êtes pas autorisé à effectuer cette action.';
    }

    if (error.response?.statusCode == 404) {
      return 'La soumission ou l’appel d’offres est introuvable.';
    }

    if (error.response?.statusCode == 409) {
      return 'Cette entreprise a déjà déposé une soumission.';
    }

    return messageParDefaut;
  }

  static String? _nullableString(
    String? valeur,
  ) {
    final texte = valeur?.trim() ?? '';

    return texte.isEmpty ? null : texte;
  }
}

class SoumissionActionResult {
  const SoumissionActionResult({
    required this.message,
    this.soumission,
  });

  final String message;
  final Soumission? soumission;
}

class SoumissionException implements Exception {
  const SoumissionException(this.message);

  final String message;

  @override
  String toString() => message;
}