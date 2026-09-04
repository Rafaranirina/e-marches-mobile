import 'dart:io';

import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// URL de base de l'API backend.
  ///
  /// `10.0.2.2` est l'alias réseau spécial de l'émulateur Android vers la
  /// machine hôte — il n'existe pas ailleurs (Windows, iOS, Android réel),
  /// d'où un défaut par plateforme plutôt qu'une valeur unique codée en dur.
  /// Surchargeable via `--dart-define=API_BASE_URL=...` (ex. IP locale pour
  /// tester depuis un vrai appareil Android).
  static String get apiBaseUrl {
    if (_override.isNotEmpty) {
      return _override;
    }

    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:5000';
    }

    return 'http://localhost:5000';
  }
}