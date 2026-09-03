import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/network/dio_error_mapper.dart';
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

      return _extraireListe(response.data, 'soumissions');
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

  /// Soumissions de l'entreprise du fournisseur connecté, brouillons inclus.
  /// C'est le seul endpoint accessible au rôle fournisseur — la liste par
  /// appel d'offres (`listerParAppelOffre`) est réservée à
  /// administration/admin_national/commission côté backend et exclut les
  /// brouillons.
  Future<List<Soumission>> listerMesSoumissions() async {
    try {
      final response = await _dio.get(
        '/api/soumissions/mes-soumissions',
      );

      return _extraireListe(response.data, 'soumissions');
    } on SoumissionException {
      rethrow;
    } on DioException catch (error) {
      throw SoumissionException(
        _extraireMessageErreur(
          error,
          'Impossible de récupérer vos soumissions.',
        ),
      );
    } catch (_) {
      throw const SoumissionException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  /// Dépose une soumission en brouillon. Le backend génère lui-même la
  /// référence (format `SOU-annee-hex`) et déduit l'entreprise du
  /// fournisseur authentifié : il ne faut envoyer ni `reference` ni
  /// `entreprise_id`.
  Future<SoumissionActionResult> deposer({
    required String appelOffreId,
    required double montantPropose,
    String? delaiExecution,
  }) async {
    try {
      final response = await _dio.post(
        '/api/soumissions',
        data: {
          'appel_offre_id': appelOffreId.trim(),
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

  /// Modifie une soumission tant qu'elle est encore en brouillon.
  Future<SoumissionActionResult> modifierBrouillon({
    required String soumissionId,
    double? montantPropose,
    String? delaiExecution,
  }) async {
    try {
      final response = await _dio.patch(
        '/api/soumissions/$soumissionId/brouillon',
        data: {
          'montant_propose': montantPropose,
          'delai_execution':
              _nullableString(delaiExecution),
        }..removeWhere((_, value) => value == null),
      );

      return _convertirResultatAction(response.data);
    } on SoumissionException {
      rethrow;
    } on DioException catch (error) {
      throw SoumissionException(
        _extraireMessageErreur(
          error,
          'Impossible de modifier la soumission.',
        ),
      );
    } catch (_) {
      throw const SoumissionException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  /// Transmet définitivement la soumission (brouillon -> soumise). Nécessite
  /// qu'au moins un document soit déjà attaché, sinon le backend refuse
  /// (400). Retourne le récépissé (référence, horodatage, empreinte).
  Future<TransmissionResult> transmettre({
    required String soumissionId,
  }) async {
    try {
      final response = await _dio.patch(
        '/api/soumissions/$soumissionId/transmettre',
      );

      final data = _convertirReponse(response.data);
      final soumissionJson = data['soumission'];
      final recepisseJson = data['recepisse'];

      if (recepisseJson is! Map) {
        throw const SoumissionException(
          'Le récépissé de transmission est manquant dans la réponse du serveur.',
        );
      }

      return TransmissionResult(
        message: data['message']?.toString() ??
            'Soumission transmise avec succès.',
        recepisse: RecepisseTransmission.fromJson(
          Map<String, dynamic>.from(recepisseJson),
        ),
        soumission: soumissionJson is Map
            ? Soumission.fromJson(
                Map<String, dynamic>.from(soumissionJson),
              )
            : null,
      );
    } on SoumissionException {
      rethrow;
    } on DioException catch (error) {
      throw SoumissionException(
        _extraireMessageErreur(
          error,
          'Impossible de transmettre la soumission.',
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

  List<Soumission> _extraireListe(
    dynamic responseData,
    String cle,
  ) {
    final data = _convertirReponse(responseData);
    final liste = data[cle];

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
          (soumission) => soumission.id.isNotEmpty,
        )
        .toList();
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
    return extraireMessageErreur(
      error,
      messageParDefaut,
      messagesParStatut: const {
        404: 'La soumission ou l’appel d’offres est introuvable.',
        409: 'Cette entreprise a déjà déposé une soumission.',
      },
    );
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

class TransmissionResult {
  const TransmissionResult({
    required this.message,
    required this.recepisse,
    this.soumission,
  });

  final String message;
  final RecepisseTransmission recepisse;
  final Soumission? soumission;
}

class SoumissionException implements Exception {
  const SoumissionException(this.message);

  final String message;

  @override
  String toString() => message;
}
