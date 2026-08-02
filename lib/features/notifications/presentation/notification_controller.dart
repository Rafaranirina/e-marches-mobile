import 'package:flutter/foundation.dart';

import '../data/notification_repository.dart';
import '../data/notification_utilisateur.dart';

class NotificationController extends ChangeNotifier {
  NotificationController({
    NotificationRepository? repository,
  }) : _repository =
            repository ?? NotificationRepository();

  final NotificationRepository _repository;

  List<NotificationUtilisateur> _notifications = [];

  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isToutMarquerLu = false;
  bool _isCreating = false;

  String? _notificationEnCoursId;
  String? _errorMessage;

  List<NotificationUtilisateur> get notifications =>
      List.unmodifiable(_notifications);

  bool get isLoading => _isLoading;

  bool get isRefreshing => _isRefreshing;

  bool get isToutMarquerLu => _isToutMarquerLu;

  bool get isCreating => _isCreating;

  bool get isBusy =>
      _isLoading ||
      _isRefreshing ||
      _isToutMarquerLu ||
      _isCreating ||
      _notificationEnCoursId != null;

  String? get errorMessage => _errorMessage;

  bool get hasError =>
      _errorMessage != null &&
      _errorMessage!.trim().isNotEmpty;

  int get nombreTotal => _notifications.length;

  int get nombreNonLues => _notifications
      .where(
        (notification) => notification.estNonLue,
      )
      .length;

  bool get hasNotifications =>
      _notifications.isNotEmpty;

  bool get hasNotificationsNonLues =>
      nombreNonLues > 0;

  bool actionEnCoursPour(
    String notificationId,
  ) {
    return _notificationEnCoursId ==
        notificationId.trim();
  }

  Future<void> charger() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.mesNotifications();

      _notifications =
          List<NotificationUtilisateur>.from(
        resultat.notifications,
      );
    } on NotificationException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible de charger les notifications.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> actualiser() async {
    if (_isRefreshing || _isLoading) {
      return;
    }

    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.mesNotifications();

      _notifications =
          List<NotificationUtilisateur>.from(
        resultat.notifications,
      );
    } on NotificationException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
          'Impossible d’actualiser les notifications.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<ActionNotificationResult?>
      marquerLue(
    NotificationUtilisateur notification,
  ) async {
    if (notification.id.trim().isEmpty) {
      _errorMessage =
          'La notification sélectionnée est invalide.';
      notifyListeners();
      return null;
    }

    if (notification.estLue) {
      return const ActionNotificationResult(
        message:
            'Cette notification est déjà marquée comme lue.',
      );
    }

    if (_notificationEnCoursId != null) {
      return null;
    }

    _notificationEnCoursId =
        notification.id.trim();

    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.marquerLue(
        notification.id,
      );

      final index = _notifications.indexWhere(
        (element) =>
            element.id == notification.id,
      );

      if (index >= 0) {
        _notifications[index] =
            resultat.notification ??
                _notifications[index]
                    .marquerCommeLue();
      }

      return resultat;
    } on NotificationException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de marquer la notification comme lue.';
      return null;
    } finally {
      _notificationEnCoursId = null;
      notifyListeners();
    }
  }

  Future<ActionNotificationResult?>
      toutMarquerCommeLu() async {
    if (_isToutMarquerLu ||
        !hasNotificationsNonLues) {
      return null;
    }

    _isToutMarquerLu = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultat =
          await _repository.toutMarquerLu();

      _notifications = _notifications
          .map(
            (notification) =>
                notification.marquerCommeLue(),
          )
          .toList();

      return resultat;
    } on NotificationException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de marquer toutes les notifications comme lues.';
      return null;
    } finally {
      _isToutMarquerLu = false;
      notifyListeners();
    }
  }

  Future<CreationNotificationResult?> creer({
    required String utilisateurId,
    required String type,
    required String titre,
    String canal = 'in_app',
    String? message,
    String? appelOffreId,
  }) async {
    if (_isCreating) {
      return null;
    }

    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _repository.creer(
        utilisateurId: utilisateurId,
        type: type,
        titre: titre,
        canal: canal,
        message: message,
        appelOffreId: appelOffreId,
      );
    } on NotificationException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          'Impossible de créer la notification.';
      return null;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  NotificationUtilisateur? trouverParId(
    String notificationId,
  ) {
    final id = notificationId.trim();

    if (id.isEmpty) {
      return null;
    }

    for (final notification in _notifications) {
      if (notification.id == id) {
        return notification;
      }
    }

    return null;
  }

  void effacerErreur() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }
}