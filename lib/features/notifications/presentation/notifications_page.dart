import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/circle_icon.dart';
import '../data/notification_utilisateur.dart';
import 'notification_controller.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationController()
        ..charger(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() =>
      _NotificationsViewState();
}

class _NotificationsViewState
    extends State<_NotificationsView> {
  bool _afficherSeulementNonLues = false;

  Future<void> _marquerLue(
    NotificationUtilisateur notification,
  ) async {
    if (notification.estLue) {
      return;
    }

    final controller =
        context.read<NotificationController>();

    final resultat =
        await controller.marquerLue(
      notification,
    );

    if (!mounted) {
      return;
    }

    _afficherMessage(
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de marquer la notification comme lue.',
      estErreur: resultat == null,
    );
  }

  Future<void> _toutMarquerLu() async {
    final controller =
        context.read<NotificationController>();

    if (!controller.hasNotificationsNonLues ||
        controller.isBusy) {
      return;
    }

    final confirmation =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Tout marquer comme lu',
          ),
          content: const Text(
            'Toutes les notifications non lues seront marquées comme lues.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Annuler',
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              icon: const Icon(
                Icons.done_all_outlined,
              ),
              label: const Text(
                'Confirmer',
              ),
            ),
          ],
        );
      },
    );

    if (confirmation != true ||
        !mounted) {
      return;
    }

    final resultat =
        await controller
            .toutMarquerCommeLu();

    if (!mounted) {
      return;
    }

    _afficherMessage(
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de mettre à jour les notifications.',
      estErreur: resultat == null,
    );
  }

  void _afficherMessage(
    String message, {
    bool estErreur = false,
  }) {
    final messenger =
        ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: estErreur
              ? Theme.of(context)
                  .colorScheme
                  .error
              : null,
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        context.watch<NotificationController>();

    final notificationsAffichees =
        _afficherSeulementNonLues
            ? controller.notifications
                .where(
                  (notification) =>
                      notification.estNonLue,
                )
                .toList()
            : controller.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
        ),
        actions: [
          IconButton(
            tooltip:
                'Tout marquer comme lu',
            onPressed:
                controller.hasNotificationsNonLues &&
                        !controller.isBusy
                    ? _toutMarquerLu
                    : null,
            icon: const Icon(
              Icons.done_all_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: controller.isBusy
                ? null
                : controller.actualiser,
            icon: const Icon(
              Icons.refresh_outlined,
            ),
          ),
        ],
        bottom: controller.isRefreshing ||
                controller.isToutMarquerLu
            ? const PreferredSize(
                preferredSize:
                    Size.fromHeight(3),
                child:
                    LinearProgressIndicator(),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _EnteteNotifications(
              nombreTotal:
                  controller.nombreTotal,
              nombreNonLues:
                  controller.nombreNonLues,
              afficherSeulementNonLues:
                  _afficherSeulementNonLues,
              onChangerFiltre: (valeur) {
                setState(() {
                  _afficherSeulementNonLues =
                      valeur;
                });
              },
            ),
            Expanded(
              child: _buildContenu(
                controller,
                notificationsAffichees,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenu(
    NotificationController controller,
    List<NotificationUtilisateur>
        notifications,
  ) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.hasError &&
        controller.notifications.isEmpty) {
      return _ErreurNotifications(
        message: controller.errorMessage ??
            'Impossible de charger les notifications.',
        onRetry: controller.charger,
      );
    }

    if (notifications.isEmpty) {
      return _NotificationsVides(
        seulementNonLues:
            _afficherSeulementNonLues,
        onActualiser:
            controller.actualiser,
      );
    }

    return RefreshIndicator(
      onRefresh: controller.actualiser,
      child: ListView.separated(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          32,
        ),
        itemCount: notifications.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final notification =
              notifications[index];

          return _NotificationCard(
            notification: notification,
            actionEnCours:
                controller.actionEnCoursPour(
              notification.id,
            ),
            onTap: () {
              _marquerLue(notification);
            },
          );
        },
      ),
    );
  }
}

class _EnteteNotifications
    extends StatelessWidget {
  const _EnteteNotifications({
    required this.nombreTotal,
    required this.nombreNonLues,
    required this.afficherSeulementNonLues,
    required this.onChangerFiltre,
  });

  final int nombreTotal;
  final int nombreNonLues;
  final bool afficherSeulementNonLues;
  final ValueChanged<bool> onChangerFiltre;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor:
                        Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                    child: Icon(
                      Icons
                          .notifications_outlined,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$nombreTotal notification'
                          '${nombreTotal > 1 ? 's' : ''}',
                          style:
                              Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          '$nombreNonLues non lue'
                          '${nombreNonLues > 1 ? 's' : ''}',
                        ),
                      ],
                    ),
                  ),
                  if (nombreNonLues > 0)
                    Badge(
                      label: Text(
                        nombreNonLues.toString(),
                      ),
                      child: const Icon(
                        Icons
                            .notifications_active_outlined,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(
                      Icons.list_outlined,
                    ),
                    label: Text(
                      'Toutes',
                    ),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(
                      Icons
                          .mark_email_unread_outlined,
                    ),
                    label: Text(
                      'Non lues',
                    ),
                  ),
                ],
                selected: {
                  afficherSeulementNonLues,
                },
                onSelectionChanged:
                    (selection) {
                  if (selection.isEmpty) {
                    return;
                  }

                  onChangerFiltre(
                    selection.first,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationCard
    extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.actionEnCours,
    required this.onTap,
  });

  final NotificationUtilisateur notification;
  final bool actionEnCours;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final couleurs =
        Theme.of(context).colorScheme;

    final fond = notification.estNonLue
        ? couleurs.primaryContainer
            .withValues(alpha: 0.35)
        : couleurs.surface;

    return Card(
      color: fond,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: actionEnCours ||
                notification.estLue
            ? null
            : onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 24,
                    child: Icon(
                      _iconeType(
                        notification.type,
                      ),
                    ),
                  ),
                  if (notification.estNonLue)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: couleurs.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: couleurs.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.titre,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight:
                                      notification
                                              .estNonLue
                                          ? FontWeight
                                              .bold
                                          : FontWeight
                                              .w600,
                                ),
                          ),
                        ),
                        if (actionEnCours)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                      ],
                    ),
                    if (notification
                        .message
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        notification.message,
                        maxLines: 4,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Chip(
                          visualDensity:
                              VisualDensity
                                  .compact,
                          avatar: const Icon(
                            Icons
                                .label_outline,
                            size: 16,
                          ),
                          label: Text(
                            notification
                                .typeFormate,
                          ),
                        ),
                        Chip(
                          visualDensity:
                              VisualDensity
                                  .compact,
                          avatar: const Icon(
                            Icons
                                .send_outlined,
                            size: 16,
                          ),
                          label: Text(
                            notification
                                .canalFormate,
                          ),
                        ),
                        if (notification
                            .concerneAppelOffre)
                          const Chip(
                            visualDensity:
                                VisualDensity
                                    .compact,
                            avatar: Icon(
                              Icons
                                  .campaign_outlined,
                              size: 16,
                            ),
                            label: Text(
                              'Appel d’offres',
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(
                          Icons
                              .schedule_outlined,
                          size: 17,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _formatDateHeure(
                              notification
                                  .dateCreation,
                            ),
                            style:
                                Theme.of(context)
                                    .textTheme
                                    .bodySmall,
                          ),
                        ),
                        if (notification.estNonLue)
                          Text(
                            'Appuyez pour marquer comme lue',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconeType(
    String type,
  ) {
    final typeNormalise =
        type.trim().toLowerCase();

    if (typeNormalise.contains(
      'appel',
    )) {
      return Icons.campaign_outlined;
    }

    if (typeNormalise.contains(
      'soumission',
    )) {
      return Icons
          .assignment_turned_in_outlined;
    }

    if (typeNormalise.contains(
      'contrat',
    )) {
      return Icons.description_outlined;
    }

    if (typeNormalise.contains(
      'paiement',
    )) {
      return Icons.payments_outlined;
    }

    if (typeNormalise.contains(
      'evaluation',
    )) {
      return Icons.leaderboard_outlined;
    }

    if (typeNormalise.contains(
      'alerte',
    )) {
      return Icons.warning_amber_outlined;
    }

    return Icons.notifications_outlined;
  }
}

class _ErreurNotifications
    extends StatelessWidget {
  const _ErreurNotifications({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleIcon.erreur(context),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_outlined,
              ),
              label: const Text(
                'Réessayer',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsVides
    extends StatelessWidget {
  const _NotificationsVides({
    required this.seulementNonLues,
    required this.onActualiser,
  });

  final bool seulementNonLues;
  final Future<void> Function() onActualiser;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onActualiser,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          CircleIcon.neutre(
            context,
            icon: seulementNonLues
                ? Icons.mark_email_read_outlined
                : Icons.notifications_none_outlined,
          ),
          const SizedBox(height: 20),
          Text(
            seulementNonLues
                ? 'Aucune notification non lue.'
                : 'Aucune notification disponible.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            seulementNonLues
                ? 'Toutes vos notifications ont été consultées.'
                : 'Les nouvelles notifications apparaîtront ici.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

String _formatDateHeure(
  DateTime? date,
) {
  if (date == null) {
    return 'Date non renseignée';
  }

  final dateLocale = date.toLocal();

  final maintenant = DateTime.now();

  final debutAujourdhui = DateTime(
    maintenant.year,
    maintenant.month,
    maintenant.day,
  );

  final debutDate = DateTime(
    dateLocale.year,
    dateLocale.month,
    dateLocale.day,
  );

  final difference =
      debutAujourdhui.difference(
    debutDate,
  );

  final heure = dateLocale.hour
      .toString()
      .padLeft(2, '0');

  final minute = dateLocale.minute
      .toString()
      .padLeft(2, '0');

  if (difference.inDays == 0) {
    return 'Aujourd’hui à $heure:$minute';
  }

  if (difference.inDays == 1) {
    return 'Hier à $heure:$minute';
  }

  final jour = dateLocale.day
      .toString()
      .padLeft(2, '0');

  final mois = dateLocale.month
      .toString()
      .padLeft(2, '0');

  return '$jour/$mois/${dateLocale.year} '
      'à $heure:$minute';
}