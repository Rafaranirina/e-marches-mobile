import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'notification_utilisateur.dart';

class NotificationRepository {
  NotificationRepository({
    Dio? dio,
  }) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<ListeNotificationsResult>
      mesNotifications() async {
    try {
      final response = await _dio.get(
        '/api/notifications/mes-notifications',
      );

      final data = _convertirMap(
        response.data,
      );

      return ListeNotificationsResult.fromJson(
        data,
      );
    } on DioException catch (error) {
      throw NotificationException(
        _extraireMessageErreur(
          error,
          'Impossible de charger les notifications.',
        ),
      );
    } on NotificationException {
      rethrow;
    } catch (_) {
      throw const NotificationException(
        'Les notifications reçues sont invalides.',
      );
    }
  }

  Future<ActionNotificationResult> marquerLue(
    String notificationId,
  ) async {
    final id = notificationId.trim();

    if (id.isEmpty) {
      throw const NotificationException(
        'La notification sélectionnée est invalide.',
      );
    }

    try {
      final response = await _dio.patch(
        '/api/notifications/$id/lu',
      );

      final data = _convertirMap(
        response.data,
      );

      NotificationUtilisateur? notification;

      final notificationData =
          data['notification'];

      if (notificationData is Map) {
        notification =
            NotificationUtilisateur.fromJson(
          Map<String, dynamic>.from(
            notificationData,
          ),
        );
      }

      return ActionNotificationResult(
        message: _extraireMessageReponse(
          data,
          'Notification marquée comme lue.',
        ),
        notification: notification,
      );
    } on DioException catch (error) {
      throw NotificationException(
        _extraireMessageErreur(
          error,
          'Impossible de marquer la notification comme lue.',
        ),
      );
    } on NotificationException {
      rethrow;
    } catch (_) {
      throw const NotificationException(
        'La réponse du serveur est invalide.',
      );
    }
  }

  Future<ActionNotificationResult>
      toutMarquerLu() async {
    try {
      final response = await _dio.patch(
        '/api/notifications/tout-lu',
      );

      final data = _convertirMap(
        response.data,
      );

      return ActionNotificationResult(
        message: _extraireMessageReponse(
          data,
          'Toutes les notifications ont été marquées comme lues.',
        ),
      );
    } on DioException catch (error) {
      throw NotificationException(
        _extraireMessageErreur(
          error,
          'Impossible de marquer toutes les notifications comme lues.',
        ),
      );
    } on NotificationException {
      rethrow;
    } catch (_) {
      throw const NotificationException(
        'La réponse du serveur est invalide.',
      );
    }
  }

  Future<CreationNotificationResult> creer({
    required String utilisateurId,
    required String type,
    required String titre,
    String canal = 'in_app',
    String? message,
    String? appelOffreId,
  }) async {
    final utilisateurIdNormalise =
        utilisateurId.trim();

    final typeNormalise = type.trim();

    final titreNormalise = titre.trim();

    final canalNormalise = canal.trim().isEmpty
        ? 'in_app'
        : canal.trim();

    if (utilisateurIdNormalise.isEmpty) {
      throw const NotificationException(
        'Le destinataire est obligatoire.',
      );
    }

    if (typeNormalise.isEmpty) {
      throw const NotificationException(
        'Le type de notification est obligatoire.',
      );
    }

    if (titreNormalise.isEmpty) {
      throw const NotificationException(
        'Le titre de la notification est obligatoire.',
      );
    }

    try {
      final response = await _dio.post(
        '/api/notifications',
        data: {
          'utilisateur_id':
              utilisateurIdNormalise,
          'type': typeNormalise,
          'canal': canalNormalise,
          'titre': titreNormalise,
          'message': _nullableString(message),
          'appel_offre_id':
              _nullableString(appelOffreId),
        },
      );

      final data = _convertirMap(
        response.data,
      );

      final notificationData =
          data['notification'];

      NotificationUtilisateur? notification;

      if (notificationData is Map) {
        notification =
            NotificationUtilisateur.fromJson(
          Map<String, dynamic>.from(
            notificationData,
          ),
        );
      }

      return CreationNotificationResult(
        message: _extraireMessageReponse(
          data,
          'Notification créée avec succès.',
        ),
        notification: notification,
      );
    } on DioException catch (error) {
      throw NotificationException(
        _extraireMessageErreur(
          error,
          'Impossible de créer la notification.',
        ),
      );
    } on NotificationException {
      rethrow;
    } catch (_) {
      throw const NotificationException(
        'La réponse du serveur est invalide.',
      );
    }
  }

  Map<String, dynamic> _convertirMap(
    dynamic valeur,
  ) {
    if (valeur is! Map) {
      throw const NotificationException(
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
        return 'Vous n’êtes pas autorisé à effectuer cette action.';

      case 404:
        return 'La notification est introuvable.';

      default:
        return messageParDefaut;
    }
  }

  String? _nullableString(
    String? valeur,
  ) {
    final texte = valeur?.trim() ?? '';

    return texte.isEmpty ? null : texte;
  }
}

class ActionNotificationResult {
  const ActionNotificationResult({
    required this.message,
    this.notification,
  });

  final String message;
  final NotificationUtilisateur? notification;
}

class CreationNotificationResult {
  const CreationNotificationResult({
    required this.message,
    this.notification,
  });

  final String message;
  final NotificationUtilisateur? notification;
}

class NotificationException implements Exception {
  const NotificationException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}