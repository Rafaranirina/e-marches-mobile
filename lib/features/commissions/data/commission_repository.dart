import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/models/commission.dart';

class CommissionRepository {
  CommissionRepository({
    Dio? dio,
  }) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<ListeCommissionsResult>
      listerParAppelOffre(
    String appelOffreId,
  ) async {
    final id = appelOffreId.trim();

    if (id.isEmpty) {
      throw const CommissionException(
        'L’appel d’offres sélectionné est invalide.',
      );
    }

    try {
      final response = await _dio.get(
        '/api/commissions/appel-offre/$id',
      );

      final data = _convertirMap(
        response.data,
      );

      return ListeCommissionsResult.fromJson(
        data,
      );
    } on DioException catch (error) {
      throw CommissionException(
        _extraireMessageErreur(
          error,
          'Impossible de charger les commissions.',
        ),
      );
    } on CommissionException {
      rethrow;
    } catch (_) {
      throw const CommissionException(
        'La liste des commissions reçue est invalide.',
      );
    }
  }

  Future<ActionCommissionResult>
      creerCommission(
    DonneesCommission donnees,
  ) async {
    final nom = donnees.nom.trim();
    final appelOffreId =
        donnees.appelOffreId.trim();

    if (nom.isEmpty) {
      throw const CommissionException(
        'Le nom de la commission est obligatoire.',
      );
    }

    if (appelOffreId.isEmpty) {
      throw const CommissionException(
        'L’appel d’offres est obligatoire.',
      );
    }

    try {
      final response = await _dio.post(
        '/api/commissions',
        data: donnees.versJson(),
      );

      final data = _convertirMap(
        response.data,
      );

      final commissionData =
          data['commission'];

      Commission? commission;

      if (commissionData is Map) {
        commission =
            Commission.fromJson(
          Map<String, dynamic>.from(
            commissionData,
          ),
        );
      }

      return ActionCommissionResult(
        message: _extraireMessageReponse(
          data,
          'Commission créée avec succès.',
        ),
        commission: commission,
      );
    } on DioException catch (error) {
      throw CommissionException(
        _extraireMessageErreur(
          error,
          'Impossible de créer la commission.',
        ),
      );
    } on CommissionException {
      rethrow;
    } catch (_) {
      throw const CommissionException(
        'La réponse du serveur est invalide.',
      );
    }
  }

  Future<ActionMembreCommissionResult>
      ajouterMembre({
    required String commissionId,
    required DonneesMembreCommission donnees,
  }) async {
    final id = commissionId.trim();
    final utilisateurId =
        donnees.utilisateurId.trim();

    if (id.isEmpty) {
      throw const CommissionException(
        'La commission sélectionnée est invalide.',
      );
    }

    if (utilisateurId.isEmpty) {
      throw const CommissionException(
        'Le membre sélectionné est invalide.',
      );
    }

    try {
      final response = await _dio.post(
        '/api/commissions/$id/membres',
        data: donnees.versJson(),
      );

      final data = _convertirMap(
        response.data,
      );

      final membreData = data['membre'];

      MembreCommission? membre;

      if (membreData is Map) {
        membre =
            MembreCommission.fromJson(
          Map<String, dynamic>.from(
            membreData,
          ),
        );
      }

      return ActionMembreCommissionResult(
        message: _extraireMessageReponse(
          data,
          'Membre ajouté à la commission.',
        ),
        membre: membre,
      );
    } on DioException catch (error) {
      throw CommissionException(
        _extraireMessageErreur(
          error,
          'Impossible d’ajouter le membre.',
        ),
      );
    } on CommissionException {
      rethrow;
    } catch (_) {
      throw const CommissionException(
        'La réponse du serveur est invalide.',
      );
    }
  }

  Map<String, dynamic> _convertirMap(
    dynamic valeur,
  ) {
    if (valeur is! Map) {
      throw const CommissionException(
        'La réponse du serveur est invalide.',
      );
    }

    return Map<String, dynamic>.from(
      valeur,
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
        return 'Vous n’êtes pas autorisé à effectuer cette opération.';

      case 404:
        return 'La commission ou l’appel d’offres est introuvable.';

      case 409:
        return 'Ce membre fait déjà partie de la commission.';

      case 500:
        return 'Une erreur interne est survenue sur le serveur.';

      default:
        return messageParDefaut;
    }
  }
}

class ActionCommissionResult {
  const ActionCommissionResult({
    required this.message,
    this.commission,
  });

  final String message;
  final Commission? commission;
}

class ActionMembreCommissionResult {
  const ActionMembreCommissionResult({
    required this.message,
    this.membre,
  });

  final String message;
  final MembreCommission? membre;
}

class CommissionException implements Exception {
  const CommissionException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}