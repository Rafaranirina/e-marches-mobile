import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../documents/presentation/documents_page.dart';
import '../data/soumission.dart';
import 'soumission_controller.dart';

class SoumissionsPage extends StatelessWidget {
  const SoumissionsPage({
    required this.appelOffreId,
    required this.appelOffreReference,
    super.key,
  });

  final String appelOffreId;
  final String appelOffreReference;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SoumissionController(
        appelOffreId: appelOffreId,
      )..charger(),
      child: _SoumissionsView(
        appelOffreReference: appelOffreReference,
      ),
    );
  }
}

class _SoumissionsView extends StatelessWidget {
  const _SoumissionsView({
    required this.appelOffreReference,
  });

  final String appelOffreReference;

  Future<void> _ouvrirDocuments(
    BuildContext context, {
    required Soumission soumission,
    required bool peutUploader,
  }) async {
    final reference = soumission.reference.trim();

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DocumentsPage(
          contexte: 'soumission',
          contexteId: soumission.id,
          titre: reference.isEmpty
              ? 'Documents de la soumission'
              : 'Documents de la soumission $reference',
          peutUploader: peutUploader,
        ),
      ),
    );
  }

  Future<void> _validerSoumission(
    BuildContext context, {
    required Soumission soumission,
    required String statut,
  }) async {
    final estRecevable = statut == 'recevable';

    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            estRecevable
                ? 'Déclarer la soumission recevable'
                : 'Déclarer la soumission irrecevable',
          ),
          content: Text(
            estRecevable
                ? 'Confirmer que cette soumission est recevable ?'
                : 'Confirmer que cette soumission est irrecevable ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );

    if (confirmation != true || !context.mounted) {
      return;
    }

    final controller =
        context.read<SoumissionController>();

    final resultat = await controller.valider(
      soumissionId: soumission.id,
      statut: statut,
    );

    if (!context.mounted) {
      return;
    }

    final message = resultat?.message ??
        controller.errorMessage ??
        'Impossible de mettre à jour la soumission.';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        context.watch<SoumissionController>();

    final role = context
            .watch<AuthController>()
            .utilisateur
            ?.role
            .trim()
            .toLowerCase() ??
        '';

    final peutValider =
        role == 'admin_national' ||
            role == 'administration';

    final peutUploaderDocuments = peutValider;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soumissions'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: controller.isLoading
                ? null
                : controller.actualiser,
            icon: const Icon(
              Icons.refresh_outlined,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _EnteteSoumissions(
              reference: appelOffreReference,
              nombre: controller.nombreTotal,
            ),
            Expanded(
              child: _buildContenu(
                context,
                controller,
                peutValider,
                peutUploaderDocuments,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenu(
    BuildContext context,
    SoumissionController controller,
    bool peutValider,
    bool peutUploaderDocuments,
  ) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.hasError &&
        controller.soumissions.isEmpty) {
      return _ErreurSoumissions(
        message: controller.errorMessage ??
            'Impossible de charger les soumissions.',
        onRetry: controller.charger,
      );
    }

    if (controller.soumissions.isEmpty) {
      return _ListeSoumissionsVide(
        onActualiser: controller.actualiser,
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
          24,
        ),
        itemCount: controller.soumissions.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final soumission =
              controller.soumissions[index];

          return _SoumissionCard(
            soumission: soumission,
            peutValider: peutValider,
            validationEnCours:
                controller.validationEnCours(
              soumission.id,
            ),
            onDocuments: () {
              _ouvrirDocuments(
                context,
                soumission: soumission,
                peutUploader:
                    peutUploaderDocuments,
              );
            },
            onRecevable: () {
              _validerSoumission(
                context,
                soumission: soumission,
                statut: 'recevable',
              );
            },
            onIrrecevable: () {
              _validerSoumission(
                context,
                soumission: soumission,
                statut: 'irrecevable',
              );
            },
          );
        },
      ),
    );
  }
}

class _EnteteSoumissions extends StatelessWidget {
  const _EnteteSoumissions({
    required this.reference,
    required this.nombre,
  });

  final String reference;
  final int nombre;

  @override
  Widget build(BuildContext context) {
    final referenceAffichee =
        reference.trim().isEmpty
            ? 'Appel d’offres'
            : reference;

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
          child: Row(
            children: [
              const CircleAvatar(
                radius: 25,
                child: Icon(
                  Icons.assignment_turned_in_outlined,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      referenceAffichee,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$nombre soumission'
                      '${nombre > 1 ? 's' : ''}',
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
}

class _SoumissionCard extends StatelessWidget {
  const _SoumissionCard({
    required this.soumission,
    required this.peutValider,
    required this.validationEnCours,
    required this.onDocuments,
    required this.onRecevable,
    required this.onIrrecevable,
  });

  final Soumission soumission;
  final bool peutValider;
  final bool validationEnCours;
  final VoidCallback onDocuments;
  final VoidCallback onRecevable;
  final VoidCallback onIrrecevable;

  @override
  Widget build(BuildContext context) {
    final statut =
        soumission.statut.trim().toLowerCase();

    final estSoumise =
        statut.isEmpty || statut == 'soumise';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                    soumission.reference.trim().isEmpty
                        ? 'Référence non renseignée'
                        : soumission.reference,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                _StatutSoumissionChip(
                  statut: soumission.statut,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InformationSoumission(
              icon: Icons.business_outlined,
              label: 'Entreprise',
              valeur: soumission.entreprise,
            ),
            const SizedBox(height: 12),
            _InformationSoumission(
              icon: Icons.payments_outlined,
              label: 'Montant proposé',
              valeur: _formatMontant(
                soumission.montantPropose,
              ),
            ),
            const SizedBox(height: 12),
            _InformationSoumission(
              icon: Icons.timer_outlined,
              label: 'Délai d’exécution',
              valeur: soumission.delaiExecution,
            ),
            const SizedBox(height: 12),
            _InformationSoumission(
              icon: Icons.schedule_outlined,
              label: 'Date de dépôt',
              valeur: _formatDate(
                soumission.horodatageDepot,
              ),
            ),
            const Divider(height: 30),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: validationEnCours
                    ? null
                    : onDocuments,
                icon: const Icon(
                  Icons.folder_outlined,
                ),
                label: const Text(
                  'Documents de la soumission',
                ),
              ),
            ),
            if (peutValider && estSoumise) ...[
              const Divider(height: 30),
              if (validationEnCours)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onIrrecevable,
                        icon: const Icon(
                          Icons.cancel_outlined,
                        ),
                        label: const Text(
                          'Irrecevable',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onRecevable,
                        icon: const Icon(
                          Icons.verified_outlined,
                        ),
                        label: const Text(
                          'Recevable',
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatMontant(
    double? montant,
  ) {
    if (montant == null) {
      return 'Non renseigné';
    }

    return '${NumberFormat.decimalPattern('fr_FR').format(montant)} Ar';
  }

  static String _formatDate(
    DateTime? date,
  ) {
    if (date == null) {
      return 'Non renseignée';
    }

    final dateLocale = date.toLocal();

    final jour = dateLocale.day
        .toString()
        .padLeft(2, '0');

    final mois = dateLocale.month
        .toString()
        .padLeft(2, '0');

    final heure = dateLocale.hour
        .toString()
        .padLeft(2, '0');

    final minute = dateLocale.minute
        .toString()
        .padLeft(2, '0');

    return '$jour/$mois/${dateLocale.year} '
        'à $heure:$minute';
  }
}

class _InformationSoumission
    extends StatelessWidget {
  const _InformationSoumission({
    required this.icon,
    required this.label,
    required this.valeur,
  });

  final IconData icon;
  final String label;
  final String? valeur;

  @override
  Widget build(BuildContext context) {
    final texte = valeur?.trim() ?? '';

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 21,
          color: Theme.of(context)
              .colorScheme
              .primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge,
              ),
              const SizedBox(height: 2),
              Text(
                texte.isEmpty
                    ? 'Non renseigné'
                    : texte,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatutSoumissionChip
    extends StatelessWidget {
  const _StatutSoumissionChip({
    required this.statut,
  });

  final String statut;

  @override
  Widget build(BuildContext context) {
    final statutNormalise =
        statut.trim().toLowerCase();

    final couleurs =
        Theme.of(context).colorScheme;

    final String libelle;
    final Color fond;
    final Color premierPlan;
    final IconData icone;

    switch (statutNormalise) {
      case 'recevable':
        libelle = 'Recevable';
        fond = couleurs.primaryContainer;
        premierPlan =
            couleurs.onPrimaryContainer;
        icone = Icons.verified_outlined;
        break;

      case 'irrecevable':
        libelle = 'Irrecevable';
        fond = couleurs.errorContainer;
        premierPlan =
            couleurs.onErrorContainer;
        icone = Icons.cancel_outlined;
        break;

      case 'soumise':
        libelle = 'Soumise';
        fond = couleurs.secondaryContainer;
        premierPlan =
            couleurs.onSecondaryContainer;
        icone = Icons.schedule_outlined;
        break;

      default:
        libelle = statutNormalise.isEmpty
            ? 'Non défini'
            : statut.replaceAll('_', ' ');

        fond =
            couleurs.surfaceContainerHighest;

        premierPlan =
            couleurs.onSurfaceVariant;

        icone = Icons.info_outline;
    }

    return Chip(
      backgroundColor: fond,
      side: BorderSide.none,
      avatar: Icon(
        icone,
        size: 17,
        color: premierPlan,
      ),
      label: Text(
        libelle,
        style: TextStyle(
          color: premierPlan,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ErreurSoumissions extends StatelessWidget {
  const _ErreurSoumissions({
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh,
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

class _ListeSoumissionsVide
    extends StatelessWidget {
  const _ListeSoumissionsVide({
    required this.onActualiser,
  });

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
          const Icon(
            Icons.inbox_outlined,
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune soumission déposée pour '
            'cet appel d’offres.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),
        ],
      ),
    );
  }
}