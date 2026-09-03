import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/fournisseur.dart';
import 'fournisseur_controller.dart';

class FournisseursPage extends StatelessWidget {
  const FournisseursPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FournisseurController()..charger(),
      child: const _FournisseursView(),
    );
  }
}

class _FournisseursView extends StatefulWidget {
  const _FournisseursView();

  @override
  State<_FournisseursView> createState() =>
      _FournisseursViewState();
}

class _FournisseursViewState
    extends State<_FournisseursView> {
  final TextEditingController _rechercheController =
      TextEditingController();

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  void _effacerRecherche() {
    _rechercheController.clear();

    context
        .read<FournisseurController>()
        .effacerRecherche();
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        context.watch<FournisseurController>();

    final estAdminNational = context
            .watch<AuthController>()
            .utilisateur
            ?.estAdministrateurNational ??
        false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fournisseurs'),
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
            _buildEntete(controller),
            Expanded(
              child: _buildContenu(
                controller,
                estAdminNational,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntete(
    FournisseurController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 36,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fournisseurs enregistrés',
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
                          '${controller.nombreTotal} fournisseur${controller.nombreTotal > 1 ? 's' : ''}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rechercheController,
            textInputAction:
                TextInputAction.search,
            onChanged: controller.rechercher,
            decoration: InputDecoration(
              labelText:
                  'Rechercher un fournisseur',
              hintText:
                  'Raison sociale, NIF, STAT ou statut',
              prefixIcon:
                  const Icon(Icons.search),
              suffixIcon:
                  _rechercheController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip:
                              'Effacer la recherche',
                          onPressed:
                              _effacerRecherche,
                          icon: const Icon(
                            Icons.clear,
                          ),
                        ),
              border:
                  const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenu(
    FournisseurController controller,
    bool estAdminNational,
  ) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.hasError) {
      return _ErreurFournisseurs(
        message: controller.errorMessage ??
            'Impossible de charger les fournisseurs.',
        onRetry: controller.charger,
      );
    }

    final fournisseurs =
        controller.fournisseurs;

    if (fournisseurs.isEmpty) {
      return _ListeVide(
        rechercheActive:
            controller.recherche.trim().isNotEmpty,
        onEffacerRecherche: _effacerRecherche,
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
        itemCount: fournisseurs.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final fournisseur = fournisseurs[index];

          return _FournisseurCard(
            fournisseur: fournisseur,
            peutValider: estAdminNational,
            validationEnCours:
                controller.validationEnCours(fournisseur.id),
            onValider: () async {
              final confirmation = await showDialog<bool>(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    title: const Text('Valider l’entreprise'),
                    content: Text(
                      'Confirmez-vous la validation de « ${fournisseur.raisonSociale} » ? '
                      'Les comptes fournisseurs en attente liés à cette entreprise seront également activés.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(false),
                        child: const Text('Annuler'),
                      ),
                      FilledButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(true),
                        child: const Text('Valider'),
                      ),
                    ],
                  );
                },
              );

              if (confirmation != true || !context.mounted) {
                return;
              }

              final message = await controller.validerEntreprise(
                fournisseur.id,
              );

              if (!context.mounted) {
                return;
              }

              final messenger = ScaffoldMessenger.of(context);

              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    backgroundColor: message == null
                        ? Theme.of(context).colorScheme.error
                        : null,
                    content: Text(
                      message ??
                          controller.errorMessage ??
                          'Impossible de valider cette entreprise.',
                    ),
                  ),
                );
            },
          );
        },
      ),
    );
  }
}

class _FournisseurCard extends StatelessWidget {
  const _FournisseurCard({
    required this.fournisseur,
    required this.peutValider,
    required this.validationEnCours,
    required this.onValider,
  });

  final Fournisseur fournisseur;
  final bool peutValider;
  final bool validationEnCours;
  final VoidCallback onValider;

  @override
  Widget build(BuildContext context) {
    final estEnAttente =
        fournisseur.statutValidation?.trim().toLowerCase() ==
            'en_attente';

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
                CircleAvatar(
                  child: Text(
                    _initiale(
                      fournisseur.raisonSociale,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    fournisseur.raisonSociale,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatutValidationChip(
                  statut:
                      fournisseur.statutValidation,
                ),
              ],
            ),
            const Divider(height: 28),
            _InformationFournisseur(
              icon: Icons.badge_outlined,
              label: 'NIF',
              valeur: fournisseur.nif,
            ),
            const SizedBox(height: 12),
            _InformationFournisseur(
              icon: Icons.numbers_outlined,
              label: 'STAT',
              valeur: fournisseur.stat,
            ),
            const SizedBox(height: 12),
            _InformationFournisseur(
              icon: Icons.event_outlined,
              label: 'Date d’inscription',
              valeur: _formatDate(
                fournisseur.dateCreation,
              ),
            ),
            if (peutValider && estEnAttente) ...[
              const Divider(height: 28),
              SizedBox(
                width: double.infinity,
                child: validationEnCours
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: onValider,
                        icon: const Icon(
                          Icons.verified_outlined,
                        ),
                        label: const Text(
                          'Valider l’entreprise',
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _initiale(String valeur) {
    final texte = valeur.trim();

    if (texte.isEmpty) {
      return '?';
    }

    return texte.substring(0, 1).toUpperCase();
  }

  static String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Non renseignée';
    }

    final dateLocale = date.toLocal();

    final jour =
        dateLocale.day.toString().padLeft(2, '0');

    final mois =
        dateLocale.month.toString().padLeft(2, '0');

    return '$jour/$mois/${dateLocale.year}';
  }
}

class _InformationFournisseur
    extends StatelessWidget {
  const _InformationFournisseur({
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

class _StatutValidationChip
    extends StatelessWidget {
  const _StatutValidationChip({
    required this.statut,
  });

  final String? statut;

  @override
  Widget build(BuildContext context) {
    final statutNormalise =
        statut?.trim().toLowerCase() ?? '';

    final couleurs =
        Theme.of(context).colorScheme;

    final String libelle;
    final Color fond;
    final Color premierPlan;
    final IconData icone;

    switch (statutNormalise) {
      // Valeurs réelles confirmées côté backend (type Postgres
      // `statut_compte`, identique à `utilisateurs.statut`) :
      // en_attente / actif / inactif / suspendu.
      case 'actif':
        libelle = 'Actif';
        fond = couleurs.primaryContainer;
        premierPlan =
            couleurs.onPrimaryContainer;
        icone = Icons.verified_outlined;
        break;

      case 'suspendu':
        libelle = 'Suspendu';
        fond = couleurs.errorContainer;
        premierPlan =
            couleurs.onErrorContainer;
        icone = Icons.pause_circle_outline;
        break;

      case 'inactif':
        libelle = 'Inactif';
        fond = couleurs.errorContainer;
        premierPlan =
            couleurs.onErrorContainer;
        icone = Icons.cancel_outlined;
        break;

      case 'en_attente':
        libelle = 'En attente';
        fond = couleurs.secondaryContainer;
        premierPlan =
            couleurs.onSecondaryContainer;
        icone = Icons.schedule_outlined;
        break;

      default:
        libelle = statutNormalise.isEmpty
            ? 'Non défini'
            : statut!
                .replaceAll('_', ' ')
                .trim();

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

class _ErreurFournisseurs
    extends StatelessWidget {
  const _ErreurFournisseurs({
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

class _ListeVide extends StatelessWidget {
  const _ListeVide({
    required this.rechercheActive,
    required this.onEffacerRecherche,
    required this.onActualiser,
  });

  final bool rechercheActive;
  final VoidCallback onEffacerRecherche;
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
          const SizedBox(height: 70),
          const Icon(
            Icons.business_outlined,
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            rechercheActive
                ? 'Aucun fournisseur ne correspond à la recherche.'
                : 'Aucun fournisseur enregistré.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),
          if (rechercheActive) ...[
            const SizedBox(height: 20),
            Center(
              child: OutlinedButton.icon(
                onPressed:
                    onEffacerRecherche,
                icon: const Icon(
                  Icons.clear,
                ),
                label: const Text(
                  'Effacer la recherche',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}