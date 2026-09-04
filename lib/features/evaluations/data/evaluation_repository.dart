import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/network/dio_error_mapper.dart';
import 'classement_soumission.dart';

class EvaluationRepository {
  EvaluationRepository({
    Dio? dio,
  }) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<List<ClassementSoumission>> classement(
    String appelOffreId,
  ) async {
    if (appelOffreId.trim().isEmpty) {
      throw const EvaluationException(
        'L’identifiant de l’appel d’offres est invalide.',
      );
    }

    try {
      final response = await _dio.get(
        '/api/evaluations/classement/$appelOffreId',
      );

      final data = _convertirReponse(response.data);
      final liste = data['classement'];

      if (liste is! List) {
        throw const EvaluationException(
          'Le classement des soumissions est invalide.',
        );
      }

      return liste
          .whereType<Map>()
          .map(
            (item) => ClassementSoumission.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where(
            (item) =>
                item.soumissionId.isNotEmpty &&
                item.reference.isNotEmpty,
          )
          .toList();
    } on EvaluationException {
      rethrow;
    } on DioException catch (error) {
      throw EvaluationException(
        _extraireMessageErreur(
          error,
          'Impossible de récupérer le classement.',
        ),
      );
    } catch (_) {
      throw const EvaluationException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  Future<EvaluationActionResult> evaluer({
    required String soumissionId,
    required String commissionId,
    required double noteTechnique,
    required double noteFinanciere,
    String? commentaire,
  }) async {
    if (soumissionId.trim().isEmpty) {
      throw const EvaluationException(
        'La soumission est invalide.',
      );
    }

    if (commissionId.trim().isEmpty) {
      throw const EvaluationException(
        'La commission est obligatoire.',
      );
    }

    try {
      final response = await _dio.post(
        '/api/evaluations',
        data: {
          'soumission_id': soumissionId.trim(),
          'commission_id': commissionId.trim(),
          'note_technique': noteTechnique,
          'note_financiere': noteFinanciere,
          'commentaire': _nullableString(commentaire),
        },
      );

      final data = _convertirReponse(response.data);
      final evaluationData = data['evaluation'];

      return EvaluationActionResult(
        message: data['message']?.toString() ??
            'Évaluation enregistrée.',
        evaluation: evaluationData is Map
            ? Map<String, dynamic>.from(evaluationData)
            : null,
      );
    } on EvaluationException {
      rethrow;
    } on DioException catch (error) {
      throw EvaluationException(
        _extraireMessageErreur(
          error,
          'Impossible d’enregistrer l’évaluation.',
        ),
      );
    } catch (_) {
      throw const EvaluationException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  Future<AttributionActionResult> attribuer({
    required String soumissionId,
    required String referenceContrat,
    String? objet,
  }) async {
    if (soumissionId.trim().isEmpty) {
      throw const EvaluationException(
        'La soumission sélectionnée est invalide.',
      );
    }

    if (referenceContrat.trim().isEmpty) {
      throw const EvaluationException(
        'La référence du contrat est obligatoire.',
      );
    }

    try {
      final response = await _dio.post(
        '/api/evaluations/attribuer',
        data: {
          'soumission_id': soumissionId.trim(),
          'reference_contrat': referenceContrat.trim(),
          'objet': _nullableString(objet),
        },
      );

      final data = _convertirReponse(response.data);
      final contratData = data['contrat'];

      return AttributionActionResult(
        message: data['message']?.toString() ??
            'Marché attribué avec succès.',
        contrat: contratData is Map
            ? Map<String, dynamic>.from(contratData)
            : null,
      );
    } on EvaluationException {
      rethrow;
    } on DioException catch (error) {
      throw EvaluationException(
        _extraireMessageErreur(
          error,
          'Impossible d’attribuer le marché.',
        ),
      );
    } catch (_) {
      throw const EvaluationException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  Map<String, dynamic> _convertirReponse(
    dynamic responseData,
  ) {
    if (responseData is! Map) {
      throw const EvaluationException(
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
        400: 'Les informations transmises sont invalides.',
        404: 'La soumission ou l’appel d’offres est introuvable.',
        409: 'Cette opération a déjà été effectuée ou la référence existe déjà.',
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

class EvaluationActionResult {
  const EvaluationActionResult({
    required this.message,
    this.evaluation,
  });

  final String message;
  final Map<String, dynamic>? evaluation;
}

class AttributionActionResult {
  const AttributionActionResult({
    required this.message,
    this.contrat,
  });

  final String message;
  final Map<String, dynamic>? contrat;
}

class EvaluationException implements Exception {
  const EvaluationException(this.message);

  final String message;

  @override
  String toString() => message;
}