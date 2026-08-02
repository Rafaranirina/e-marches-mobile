class NotificationUtilisateur {
  const NotificationUtilisateur({
    required this.id,
    required this.type,
    required this.canal,
    required this.titre,
    required this.message,
    required this.estLue,
    this.appelOffreId,
    this.dateCreation,
  });

  final String id;
  final String type;
  final String canal;
  final String titre;
  final String message;
  final bool estLue;
  final String? appelOffreId;
  final DateTime? dateCreation;

  factory NotificationUtilisateur.fromJson(
    Map<String, dynamic> json,
  ) {
    return NotificationUtilisateur(
      id: _parseString(
        json['id'],
      ),
      type: _parseString(
        json['type'],
      ),
      canal: _parseString(
        json['canal'],
        valeurParDefaut: 'in_app',
      ),
      titre: _parseString(
        json['titre'],
      ),
      message: _parseString(
        json['message'],
      ),
      estLue: _parseBool(
        json['lu'],
      ),
      appelOffreId: _parseStringNullable(
        json['appel_offre_id'],
      ),
      dateCreation: _parseDate(
        json['date_creation'],
      ),
    );
  }

  NotificationUtilisateur copyWith({
    String? id,
    String? type,
    String? canal,
    String? titre,
    String? message,
    bool? estLue,
    String? appelOffreId,
    DateTime? dateCreation,
  }) {
    return NotificationUtilisateur(
      id: id ?? this.id,
      type: type ?? this.type,
      canal: canal ?? this.canal,
      titre: titre ?? this.titre,
      message: message ?? this.message,
      estLue: estLue ?? this.estLue,
      appelOffreId:
          appelOffreId ?? this.appelOffreId,
      dateCreation:
          dateCreation ?? this.dateCreation,
    );
  }

  NotificationUtilisateur marquerCommeLue() {
    if (estLue) {
      return this;
    }

    return copyWith(
      estLue: true,
    );
  }

  bool get estNonLue => !estLue;

  bool get concerneAppelOffre =>
      appelOffreId != null &&
      appelOffreId!.trim().isNotEmpty;

  String get typeFormate {
    final valeur = type
        .replaceAll('_', ' ')
        .trim();

    if (valeur.isEmpty) {
      return 'Notification';
    }

    return valeur[0].toUpperCase() +
        valeur.substring(1);
  }

  String get canalFormate {
    switch (canal.trim().toLowerCase()) {
      case 'in_app':
        return 'Application';

      case 'email':
        return 'E-mail';

      case 'sms':
        return 'SMS';

      default:
        final valeur = canal
            .replaceAll('_', ' ')
            .trim();

        return valeur.isEmpty
            ? 'Application'
            : valeur;
    }
  }
}

class ListeNotificationsResult {
  const ListeNotificationsResult({
    required this.nombre,
    required this.nonLues,
    required this.notifications,
  });

  final int nombre;
  final int nonLues;
  final List<NotificationUtilisateur>
      notifications;

  factory ListeNotificationsResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final liste =
        json['notifications'];

    final notifications =
        liste is List
            ? liste
                .whereType<Map>()
                .map(
                  (element) =>
                      NotificationUtilisateur
                          .fromJson(
                    Map<String, dynamic>.from(
                      element,
                    ),
                  ),
                )
                .where(
                  (notification) =>
                      notification.id.isNotEmpty &&
                      notification
                          .titre.isNotEmpty,
                )
                .toList()
            : <NotificationUtilisateur>[];

    return ListeNotificationsResult(
      nombre: _parseInt(
        json['nombre'],
        valeurParDefaut:
            notifications.length,
      ),
      nonLues: _parseInt(
        json['non_lues'],
        valeurParDefaut: notifications
            .where(
              (notification) =>
                  notification.estNonLue,
            )
            .length,
      ),
      notifications: notifications,
    );
  }

  static const vide =
      ListeNotificationsResult(
    nombre: 0,
    nonLues: 0,
    notifications: [],
  );
}

String _parseString(
  dynamic valeur, {
  String valeurParDefaut = '',
}) {
  final texte =
      valeur?.toString().trim() ?? '';

  return texte.isEmpty
      ? valeurParDefaut
      : texte;
}

String? _parseStringNullable(
  dynamic valeur,
) {
  final texte =
      valeur?.toString().trim() ?? '';

  return texte.isEmpty ? null : texte;
}

bool _parseBool(
  dynamic valeur,
) {
  if (valeur is bool) {
    return valeur;
  }

  if (valeur is num) {
    return valeur != 0;
  }

  final texte = valeur
      ?.toString()
      .trim()
      .toLowerCase();

  return texte == 'true' ||
      texte == '1' ||
      texte == 'oui';
}

int _parseInt(
  dynamic valeur, {
  int valeurParDefaut = 0,
}) {
  if (valeur == null) {
    return valeurParDefaut;
  }

  if (valeur is int) {
    return valeur;
  }

  if (valeur is num) {
    return valeur.toInt();
  }

  final texte =
      valeur.toString().trim();

  if (texte.isEmpty) {
    return valeurParDefaut;
  }

  return int.tryParse(texte) ??
      double.tryParse(texte)?.toInt() ??
      valeurParDefaut;
}

DateTime? _parseDate(
  dynamic valeur,
) {
  final texte =
      valeur?.toString().trim() ?? '';

  if (texte.isEmpty) {
    return null;
  }

  return DateTime.tryParse(texte);
}