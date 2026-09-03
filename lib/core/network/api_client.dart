import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';

abstract final class ApiClient {
  static final SecureStorageService _storage = SecureStorageService();

  /// Chemins pour lesquels un 401 est un échec d'identifiants normal (mauvais
  /// mot de passe, code 2FA invalide) et ne doit donc PAS déclencher
  /// [onUnauthorized] — ce callback est réservé à l'expiration d'un token
  /// déjà accepté ailleurs dans l'app.
  static const _cheminsExclusDe401Global = [
    '/api/auth/login',
    '/api/auth/2fa/valider-login',
  ];

  /// Déclenché sur toute réponse 401 en dehors des chemins ci-dessus.
  /// Assigné une seule fois au démarrage (voir main.dart) pour déconnecher
  /// automatiquement l'utilisateur quand son token expire.
  static void Function()? onUnauthorized;

  static final Dio dio = _createDio();

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getAccessToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
        onError: (error, handler) {
          final chemin = error.requestOptions.path;

          if (error.response?.statusCode == 401 &&
              !_cheminsExclusDe401Global.any(
                (exclu) => chemin.contains(exclu),
              )) {
            onUnauthorized?.call();
          }

          handler.next(error);
        },
      ),
    );

    return dio;
  }
}