import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'login_result.dart';

class AuthRepository {
  AuthRepository({
    Dio? dio,
    SecureStorageService? storage,
  })  : _dio = dio ?? ApiClient.dio,
        _storage = storage ?? SecureStorageService();

  final Dio _dio;
  final SecureStorageService _storage;

  Future<LoginResult> login({
    required String email,
    required String motDePasse,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {
          'email': email.trim(),
          'mot_de_passe': motDePasse,
        },
      );

      final responseData = response.data;

      if (responseData is! Map) {
        return const LoginResult(
          statut: 'erreur',
          message: 'Réponse invalide du serveur.',
        );
      }

      final result = LoginResult.fromJson(
        Map<String, dynamic>.from(responseData),
      );

      final token = result.accessToken;

      if (result.isSuccess && token != null && token.isNotEmpty) {
        await _storage.saveAccessToken(token);
      }

      return result;
    } on DioException catch (error) {
      final responseData = error.response?.data;

      if (responseData is Map) {
        return LoginResult.fromJson(
          Map<String, dynamic>.from(responseData),
        );
      }

      return const LoginResult(
        statut: 'erreur',
        message:
            'Impossible de communiquer avec le serveur. Vérifiez que le backend est démarré.',
      );
    } catch (error) {
      return LoginResult(
        statut: 'erreur',
        message: 'Erreur inattendue : $error',
      );
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }
}