import 'package:dio/dio.dart';

/// Factorise la logique de conversion `DioException -> message utilisateur`
/// dupliquée (avec de légères variations) dans la quasi-totalité des
/// repositories de l'app. `messagesParStatut` permet à chaque appelant de
/// personnaliser le message pour un code HTTP donné (ex. 409 = "déjà
/// existant") tout en gardant la logique réseau/générique commune.
String extraireMessageErreur(
  DioException error,
  String messageParDefaut, {
  Map<int, String>? messagesParStatut,
}) {
  final responseData = error.response?.data;

  if (responseData is Map) {
    final message = responseData['message']?.toString().trim();

    if (message != null && message.isNotEmpty) {
      return message;
    }
  }

  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout) {
    return 'Le serveur met trop de temps à répondre.';
  }

  if (error.type == DioExceptionType.connectionError) {
    return 'Connexion au serveur impossible.';
  }

  final statutHttp = error.response?.statusCode;

  if (statutHttp != null) {
    final messagePersonnalise = messagesParStatut?[statutHttp];

    if (messagePersonnalise != null) {
      return messagePersonnalise;
    }

    switch (statutHttp) {
      case 401:
        return 'Votre session a expiré. Reconnectez-vous.';

      case 403:
        return 'Vous n’êtes pas autorisé à effectuer cette action.';

      case 404:
        return 'La ressource demandée est introuvable.';

      case 500:
        return 'Une erreur interne est survenue sur le serveur.';
    }
  }

  return messageParDefaut;
}
