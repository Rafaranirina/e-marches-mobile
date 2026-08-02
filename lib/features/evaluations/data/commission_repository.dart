import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'commission_option.dart';
import 'membre_commission_option.dart';

class CommissionRepository {
  CommissionRepository({
    Dio? dio,
  }) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<List<CommissionOption>> listerParAppelOffre(
    String appelOffreId,
  ) async {
    if (appelOffreId.trim().isEmpty) {
      throw const CommissionException(
        'L’identifiant de l’appel d’offres est invalide.',
      );
    }

    try {
      final response = await _dio.get(
        '/api/commissions/appel-offre/${appelOffreId.trim()}',
      );

      final data = _convertirReponse(
        response.data,
      );

      final liste = data['commissions'];

      if (liste is! List) {
        throw const CommissionException(
          'La liste des commissions est invalide.',
        );
      }

      return liste
          .whereType<Map>()
          .map(
            (item) => CommissionOption.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where(
            (commission) =>
                commission.id.isNotEmpty &&
                commission.nom.isNotEmpty,
          )
          .toList();
    } on CommissionException {
      rethrow;
    } on DioException catch (error) {
      throw CommissionException(
        _extraireMessageErreur(
          error,
          'Impossible de récupérer les commissions.',
        ),
      );
    } catch (_) {
      throw const CommissionException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  Future<CreationCommissionResult> creerCommission({
    required String nom,
    required String appelOffreId,
  }) async {
    final nomNormalise = nom.trim();
    final appelOffreIdNormalise =
        appelOffreId.trim();

    if (nomNormalise.isEmpty) {
      throw const CommissionException(
        'Le nom de la commission est obligatoire.',
      );
    }

    if (appelOffreIdNormalise.isEmpty) {
      throw const CommissionException(
        'L’appel d’offres est invalide.',
      );
    }

    try {
      final response = await _dio.post(
        '/api/commissions',
        data: {
          'nom': nomNormalise,
          'appel_offre_id':
              appelOffreIdNormalise,
        },
      );

      final data = _convertirReponse(
        response.data,
      );

      final commissionData =
          data['commission'];

      CommissionOption? commission;

      if (commissionData is Map) {
        commission =
            CommissionOption.fromJson(
          Map<String, dynamic>.from(
            commissionData,
          ),
        );
      }

      return CreationCommissionResult(
        message: _extraireMessageReponse(
          data,
          'Commission créée avec succès.',
        ),
        commission: commission,
      );
    } on CommissionException {
      rethrow;
    } on DioException catch (error) {
      throw CommissionException(
        _extraireMessageErreur(
          error,
          'Impossible de créer la commission.',
        ),
      );
    } catch (_) {
      throw const CommissionException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  Future<List<MembreCommissionOption>>
      listerMembresDisponibles() async {
    try {
      final response = await _dio.get(
        '/api/users/membres-commission',
      );

      final data = _convertirReponse(
        response.data,
      );

      final liste = data['utilisateurs'];

      if (liste is! List) {
        throw const CommissionException(
          'La liste des membres disponibles est invalide.',
        );
      }

      return liste
          .whereType<Map>()
          .map(
            (item) =>
                MembreCommissionOption.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where(
            (membre) =>
                membre.id.isNotEmpty &&
                membre.nom.isNotEmpty &&
                membre.email.isNotEmpty,
          )
          .toList();
    } on CommissionException {
      rethrow;
    } on DioException catch (error) {
      throw CommissionException(
        _extraireMessageErreur(
          error,
          'Impossible de récupérer les membres disponibles.',
        ),
      );
    } catch (_) {
      throw const CommissionException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  Future<AjoutMembreCommissionResult>
      ajouterMembre({
    required String commissionId,
    required String utilisateurId,
    String? fonction,
  }) async {
    final commissionIdNormalise =
        commissionId.trim();

    final utilisateurIdNormalise =
        utilisateurId.trim();

    if (commissionIdNormalise.isEmpty) {
      throw const CommissionException(
        'La commission sélectionnée est invalide.',
      );
    }

    if (utilisateurIdNormalise.isEmpty) {
      throw const CommissionException(
        'Le membre sélectionné est invalide.',
      );
    }

    try {
      final response = await _dio.post(
        '/api/commissions/$commissionIdNormalise/membres',
        data: {
          'utilisateur_id':
              utilisateurIdNormalise,
          'fonction': _nullableString(
            fonction,
          ),
        },
      );

      final data = _convertirReponse(
        response.data,
      );

      final membreData = data['membre'];

      return AjoutMembreCommissionResult(
        message: _extraireMessageReponse(
          data,
          'Membre ajouté à la commission.',
        ),
        membre: membreData is Map
            ? Map<String, dynamic>.from(
                membreData,
              )
            : null,
      );
    } on CommissionException {
      rethrow;
    } on DioException catch (error) {
      throw CommissionException(
        _extraireMessageErreur(
          error,
          'Impossible d’ajouter le membre à la commission.',
        ),
      );
    } catch (_) {
      throw const CommissionException(
        'Une erreur inattendue est survenue.',
      );
    }
  }

  Map<String, dynamic> _convertirReponse(
    dynamic responseData,
  ) {
    if (responseData is! Map) {
      throw const CommissionException(
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
        return 'Les informations transmises sont invalides.';

      case 401:
        return 'Votre session a expiré. Reconnectez-vous.';

      case 403:
        return 'Vous n’êtes pas autorisé à effectuer cette action.';

      case 404:
        return 'La commission, l’utilisateur ou l’appel d’offres est introuvable.';

      case 409:
        return 'Cette opération a déjà été effectuée.';

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

class CreationCommissionResult {
  const CreationCommissionResult({
    required this.message,
    this.commission,
  });

  final String message;
  final CommissionOption? commission;
}

class AjoutMembreCommissionResult {
  const AjoutMembreCommissionResult({
    required this.message,
    this.membre,
  });

  final String message;
  final Map<String, dynamic>? membre;
}

class CommissionException implements Exception {
  const CommissionException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}