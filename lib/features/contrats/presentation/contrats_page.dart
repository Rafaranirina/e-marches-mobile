import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/contrat.dart';
import 'contrat_controller.dart';
import 'contrat_details_page.dart';

class ContratsPage extends StatelessWidget {
  const ContratsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ContratController()
        ..charger(),
      child: const _ContratsView(),
    );
  }
}

class _ContratsView extends StatefulWidget {
  const _ContratsView();

  @override
  State<_ContratsView> createState() =>
      _ContratsViewState();
}

class _ContratsViewState
    extends State<_ContratsView> {
  final TextEditingController
      _rechercheController =
      TextEditingController();

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  Future<void> _ouvrirContrat(
    Contrat contrat,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ContratDetailsPage(
          contratId: contrat.id,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await context
        .read<ContratController>()
        .actualiser();
  }

  void _reinitialiserFiltres(
    ContratController controller,
  ) {
    _rechercheController.clear();
    controller.reinitialiserFiltres();
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        context.watch<ContratController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Contrats',
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: controller.isLoading ||
                    controller.isRefreshing
                ? null
                : () {
                    controller.actualiser();
                  },
            icon: const Icon(
              Icons.refresh_outlined,
            ),
          ),
        ],
        bottom: controller.isRefreshing
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
            _EnteteContrats(
              nombreContrats:
                  controller.nombreContrats,
              nombreEnCours:
                  controller.nombreParStatut(
                'en_cours',
              ),
              nombreSuspendus:
                  controller.nombreParStatut(
                'suspendu',
              ),
              nombreTermines:
                  controller.nombreParStatut(
                'termine',
              ),
            ),
            _ZoneRechercheEtFiltres(
              rechercheController:
                  _rechercheController,
              statutSelectionne:
                  controller
                      .statutSelectionne,
              onRecherche:
                  controller.rechercher,
              onStatutSelectionne:
                  controller
                      .filtrerParStatut,
              onReinitialiser: () {
                _reinitialiserFiltres(
                  controller,
                );
              },
            ),
            Expanded(
              child: _buildContenu(
                controller,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenu(
    ContratController controller,
  ) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.hasError &&
        controller.contrats.isEmpty) {
      return _ErreurContrats(
        message: controller.errorMessage ??
            'Impossible de charger les contrats.',
        onRetry: controller.charger,
      );
    }

    final contrats =
        controller.contratsFiltres;

    if (controller.contrats.isEmpty) {
      return _ListeContratsVide(
        message:
            'Aucun contrat n’est encore enregistré.',
        onActualiser:
            controller.actualiser,
      );
    }

    if (contrats.isEmpty) {
      return _ListeContratsVide(
        message:
            'Aucun contrat ne correspond aux critères sélectionnés.',
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
          24,
        ),
        itemCount: contrats.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final contrat = contrats[index];

          return _ContratCard(
            contrat: contrat,
            onTap: () {
              _ouvrirContrat(contrat);
            },
          );
        },
      ),
    );
  }
}

class _EnteteContrats extends StatelessWidget {
  const _EnteteContrats({
    required this.nombreContrats,
    required this.nombreEnCours,
    required this.nombreSuspendus,
    required this.nombreTermines,
  });

  final int nombreContrats;
  final int nombreEnCours;
  final int nombreSuspendus;
  final int nombreTermines;

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
                  const CircleAvatar(
                    radius: 26,
                    child: Icon(
                      Icons
                          .description_outlined,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$nombreContrats contrat'
                          '${nombreContrats > 1 ? 's' : ''}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Suivi des marchés attribués et des paiements',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CompteurChip(
                    label: 'En cours',
                    nombre: nombreEnCours,
                    icon: Icons
                        .play_circle_outline,
                  ),
                  _CompteurChip(
                    label: 'Suspendus',
                    nombre:
                        nombreSuspendus,
                    icon: Icons
                        .pause_circle_outline,
                  ),
                  _CompteurChip(
                    label: 'Terminés',
                    nombre:
                        nombreTermines,
                    icon: Icons
                        .check_circle_outline,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompteurChip extends StatelessWidget {
  const _CompteurChip({
    required this.label,
    required this.nombre,
    required this.icon,
  });

  final String label;
  final int nombre;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        icon,
        size: 18,
      ),
      label: Text(
        '$label : $nombre',
      ),
    );
  }
}

class _ZoneRechercheEtFiltres
    extends StatelessWidget {
  const _ZoneRechercheEtFiltres({
    required this.rechercheController,
    required this.statutSelectionne,
    required this.onRecherche,
    required this.onStatutSelectionne,
    required this.onReinitialiser,
  });

  final TextEditingController
      rechercheController;

  final String? statutSelectionne;

  final ValueChanged<String> onRecherche;

  final ValueChanged<String?>
      onStatutSelectionne;

  final VoidCallback onReinitialiser;

  @override
  Widget build(BuildContext context) {
    final filtresActifs =
        rechercheController.text
                .trim()
                .isNotEmpty ||
            statutSelectionne != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        8,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller:
                rechercheController,
            onChanged: onRecherche,
            textInputAction:
                TextInputAction.search,
            decoration: InputDecoration(
              labelText:
                  'Rechercher un contrat',
              hintText:
                  'Référence, entreprise, administration...',
              prefixIcon: const Icon(
                Icons.search_outlined,
              ),
              suffixIcon:
                  rechercheController.text
                          .isNotEmpty
                      ? IconButton(
                          tooltip:
                              'Effacer la recherche',
                          onPressed: () {
                            rechercheController
                                .clear();

                            onRecherche('');
                          },
                          icon: const Icon(
                            Icons.close,
                          ),
                        )
                      : null,
              border:
                  const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection:
                Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text(
                    'Tous',
                  ),
                  selected:
                      statutSelectionne ==
                          null,
                  onSelected: (_) {
                    onStatutSelectionne(
                      null,
                    );
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text(
                    'En cours',
                  ),
                  selected:
                      statutSelectionne ==
                          'en_cours',
                  onSelected: (_) {
                    onStatutSelectionne(
                      'en_cours',
                    );
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text(
                    'Suspendus',
                  ),
                  selected:
                      statutSelectionne ==
                          'suspendu',
                  onSelected: (_) {
                    onStatutSelectionne(
                      'suspendu',
                    );
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text(
                    'Terminés',
                  ),
                  selected:
                      statutSelectionne ==
                          'termine',
                  onSelected: (_) {
                    onStatutSelectionne(
                      'termine',
                    );
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text(
                    'Résiliés',
                  ),
                  selected:
                      statutSelectionne ==
                          'resilie',
                  onSelected: (_) {
                    onStatutSelectionne(
                      'resilie',
                    );
                  },
                ),
                if (filtresActifs) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed:
                        onReinitialiser,
                    icon: const Icon(
                      Icons
                          .filter_alt_off_outlined,
                    ),
                    label: const Text(
                      'Réinitialiser',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContratCard extends StatelessWidget {
  const _ContratCard({
    required this.contrat,
    required this.onTap,
  });

  final Contrat contrat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reference =
        contrat.reference.trim().isEmpty
            ? 'Contrat sans référence'
            : contrat.reference;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    child: Icon(
                      Icons
                          .description_outlined,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          reference,
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
                          _valeurOuDefaut(
                            contrat.objet,
                            defaut:
                                'Objet non renseigné',
                          ),
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatutContratChip(
                    statut:
                        contrat.statut,
                  ),
                ],
              ),
              const Divider(height: 28),
              _InformationContrat(
                icon:
                    Icons.business_outlined,
                label: 'Entreprise',
                valeur:
                    _valeurOuDefaut(
                  contrat.entreprise,
                  defaut:
                      'Non renseignée',
                ),
              ),
              const SizedBox(height: 12),
              _InformationContrat(
                icon: Icons
                    .account_balance_outlined,
                label: 'Administration',
                valeur:
                    _valeurOuDefaut(
                  contrat.administration,
                  defaut:
                      'Non renseignée',
                ),
              ),
              const SizedBox(height: 12),
              _InformationContrat(
                icon:
                    Icons.payments_outlined,
                label: 'Montant',
                valeur: _formatMontant(
                  contrat.montant,
                ),
              ),
              const SizedBox(height: 12),
              _InformationContrat(
                icon:
                    Icons.event_outlined,
                label: 'Période',
                valeur: _formatPeriode(
                  contrat.dateDebut,
                  contrat.dateFin,
                ),
              ),
              const SizedBox(height: 14),
              const Align(
                alignment:
                    Alignment.centerRight,
                child: Icon(
                  Icons.chevron_right,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InformationContrat
    extends StatelessWidget {
  const _InformationContrat({
    required this.icon,
    required this.label,
    required this.valeur,
  });

  final IconData icon;
  final String label;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
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
              Text(valeur),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatutContratChip
    extends StatelessWidget {
  const _StatutContratChip({
    required this.statut,
  });

  final String statut;

  @override
  Widget build(BuildContext context) {
    final couleurs =
        Theme.of(context).colorScheme;

    final statutNormalise =
        statut.trim().toLowerCase();

    final String texte;
    final Color fond;
    final Color premierPlan;
    final IconData icone;

    switch (statutNormalise) {
      case 'en_cours':
        texte = 'En cours';
        fond =
            couleurs.primaryContainer;
        premierPlan =
            couleurs.onPrimaryContainer;
        icone =
            Icons.play_circle_outline;
        break;

      case 'suspendu':
        texte = 'Suspendu';
        fond =
            couleurs.secondaryContainer;
        premierPlan =
            couleurs.onSecondaryContainer;
        icone =
            Icons.pause_circle_outline;
        break;

      case 'termine':
        texte = 'Terminé';
        fond =
            couleurs.tertiaryContainer;
        premierPlan =
            couleurs.onTertiaryContainer;
        icone =
            Icons.check_circle_outline;
        break;

      case 'resilie':
        texte = 'Résilié';
        fond =
            couleurs.errorContainer;
        premierPlan =
            couleurs.onErrorContainer;
        icone =
            Icons.cancel_outlined;
        break;

      default:
        texte = statutNormalise.isEmpty
            ? 'Non défini'
            : statut.replaceAll('_', ' ');

        fond =
            couleurs.surfaceContainerHighest;

        premierPlan =
            couleurs.onSurfaceVariant;

        icone =
            Icons.info_outline;
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
        texte,
        style: TextStyle(
          color: premierPlan,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ErreurContrats extends StatelessWidget {
  const _ErreurContrats({
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

class _ListeContratsVide
    extends StatelessWidget {
  const _ListeContratsVide({
    required this.message,
    required this.onActualiser,
  });

  final String message;
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
            Icons.description_outlined,
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            message,
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

String _formatMontant(
  double? montant,
) {
  if (montant == null) {
    return 'Non renseigné';
  }

  return '${NumberFormat.decimalPattern('fr_FR').format(montant)} Ar';
}

String _formatDate(
  DateTime? date,
) {
  if (date == null) {
    return 'Non renseignée';
  }

  final dateLocale =
      date.toLocal();

  final jour = dateLocale.day
      .toString()
      .padLeft(2, '0');

  final mois = dateLocale.month
      .toString()
      .padLeft(2, '0');

  return '$jour/$mois/${dateLocale.year}';
}

String _formatPeriode(
  DateTime? dateDebut,
  DateTime? dateFin,
) {
  if (dateDebut == null &&
      dateFin == null) {
    return 'Non renseignée';
  }

  if (dateDebut != null &&
      dateFin != null) {
    return '${_formatDate(dateDebut)} au '
        '${_formatDate(dateFin)}';
  }

  if (dateDebut != null) {
    return 'À partir du '
        '${_formatDate(dateDebut)}';
  }

  return 'Jusqu’au '
      '${_formatDate(dateFin)}';
}

String _valeurOuDefaut(
  String? valeur, {
  required String defaut,
}) {
  final texte =
      valeur?.trim() ?? '';

  return texte.isEmpty
      ? defaut
      : texte;
}