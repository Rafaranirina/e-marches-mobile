import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/rapport_tableau_bord.dart';
import 'rapport_controller.dart';

class RapportsPage extends StatelessWidget {
  const RapportsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RapportController()
        ..charger(),
      child: const _RapportsView(),
    );
  }
}

class _RapportsView extends StatelessWidget {
  const _RapportsView();

  @override
  Widget build(BuildContext context) {
    final controller =
        context.watch<RapportController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rapports et statistiques',
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: controller.isBusy
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
        child: _buildContenu(
          context,
          controller,
        ),
      ),
    );
  }

  Widget _buildContenu(
    BuildContext context,
    RapportController controller,
  ) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.hasError &&
        !controller.hasData) {
      return _ErreurRapports(
        message: controller.errorMessage ??
            'Impossible de charger les rapports.',
        onRetry: controller.charger,
      );
    }

    return RefreshIndicator(
      onRefresh: controller.actualiser,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          32,
        ),
        children: [
          if (controller.hasError) ...[
            _AvertissementRapports(
              message: controller.errorMessage!,
            ),
            const SizedBox(height: 12),
          ],
          _EnteteRapports(
            statistiques:
                controller.statistiques,
          ),
          const SizedBox(height: 16),
          _CompteursRapports(
            statistiques:
                controller.statistiques,
          ),
          const SizedBox(height: 16),
          _MontantContratsCard(
            montant: controller
                .statistiques
                .montantTotalContrats,
          ),
          const SizedBox(height: 16),
          _RepartitionCard(
            titre:
                'Appels d’offres par statut',
            icone:
                Icons.donut_large_outlined,
            elements: controller
                .statistiques
                .appelsParStatut,
            transformerLibelle:
                _libelleStatut,
          ),
          const SizedBox(height: 16),
          _RepartitionCard(
            titre:
                'Appels d’offres par type de marché',
            icone:
                Icons.category_outlined,
            elements: controller
                .statistiques
                .appelsParType,
            transformerLibelle:
                _libelleTypeMarche,
          ),
          const SizedBox(height: 16),
          _TopEntreprisesCard(
            entreprises:
                controller.topEntreprises,
          ),
          const SizedBox(height: 16),
          _ActivitesRecentesCard(
            activites:
                controller.activitesRecentes,
          ),
        ],
      ),
    );
  }
}

class _EnteteRapports extends StatelessWidget {
  const _EnteteRapports({
    required this.statistiques,
  });

  final StatistiquesTableauBord statistiques;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor:
                  Theme.of(context)
                      .colorScheme
                      .primaryContainer,
              child: Icon(
                Icons.analytics_outlined,
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vue d’ensemble des marchés publics',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${statistiques.totalAppelsOffres} '
                    'appel${statistiques.totalAppelsOffres > 1 ? 's' : ''} '
                    'd’offres, '
                    '${statistiques.totalSoumissions} '
                    'soumission${statistiques.totalSoumissions > 1 ? 's' : ''} '
                    'et '
                    '${statistiques.totalContrats} '
                    'contrat${statistiques.totalContrats > 1 ? 's' : ''}.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompteursRapports extends StatelessWidget {
  const _CompteursRapports({
    required this.statistiques,
  });

  final StatistiquesTableauBord statistiques;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, contraintes) {
        final largeur = contraintes.maxWidth;

        final largeurCarte = largeur >= 700
            ? (largeur - 24) / 3
            : largeur >= 480
                ? (largeur - 12) / 2
                : largeur;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: largeurCarte,
              child: _CompteurCard(
                titre: 'Appels d’offres',
                valeur: statistiques
                    .totalAppelsOffres,
                icone:
                    Icons.campaign_outlined,
              ),
            ),
            SizedBox(
              width: largeurCarte,
              child: _CompteurCard(
                titre: 'Appels publiés',
                valeur:
                    statistiques.appelsPublies,
                icone:
                    Icons.public_outlined,
              ),
            ),
            SizedBox(
              width: largeurCarte,
              child: _CompteurCard(
                titre: 'Appels attribués',
                valeur: statistiques
                    .appelsAttribues,
                icone:
                    Icons.verified_outlined,
              ),
            ),
            SizedBox(
              width: largeurCarte,
              child: _CompteurCard(
                titre: 'Soumissions',
                valeur: statistiques
                    .totalSoumissions,
                icone: Icons
                    .assignment_turned_in_outlined,
              ),
            ),
            SizedBox(
              width: largeurCarte,
              child: _CompteurCard(
                titre: 'Contrats',
                valeur:
                    statistiques.totalContrats,
                icone:
                    Icons.description_outlined,
              ),
            ),
            SizedBox(
              width: largeurCarte,
              child: _CompteurCard(
                titre: 'Entreprises',
                valeur: statistiques
                    .totalEntreprises,
                icone:
                    Icons.business_outlined,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CompteurCard extends StatelessWidget {
  const _CompteurCard({
    required this.titre,
    required this.valeur,
    required this.icone,
  });

  final String titre;
  final int valeur;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              child: Icon(icone),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    NumberFormat.decimalPattern(
                      'fr_FR',
                    ).format(valeur),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(titre),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MontantContratsCard
    extends StatelessWidget {
  const _MontantContratsCard({
    required this.montant,
  });

  final double montant;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 27,
              child: const Icon(
                Icons
                    .account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Montant total des contrats',
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatMontant(montant),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepartitionCard extends StatelessWidget {
  const _RepartitionCard({
    required this.titre,
    required this.icone,
    required this.elements,
    required this.transformerLibelle,
  });

  final String titre;
  final IconData icone;
  final List<RepartitionAppelOffre> elements;
  final String Function(String valeur)
      transformerLibelle;

  @override
  Widget build(BuildContext context) {
    final maximum = elements.isEmpty
        ? 0
        : elements
            .map((element) => element.nombre)
            .reduce(
              (valeurA, valeurB) =>
                  valeurA > valeurB
                      ? valeurA
                      : valeurB,
            );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            _TitreSection(
              titre: titre,
              icone: icone,
              compteur: elements.length,
            ),
            const Divider(height: 28),
            if (elements.isEmpty)
              const _MessageVide(
                message:
                    'Aucune donnée de répartition disponible.',
              )
            else
              ...elements.map(
                (element) {
                  final progression =
                      maximum <= 0
                          ? 0.0
                          : element.nombre /
                              maximum;

                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 18,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                transformerLibelle(
                                  element.libelle,
                                ),
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              element.nombre
                                  .toString(),
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progression,
                          minHeight: 8,
                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _TopEntreprisesCard
    extends StatelessWidget {
  const _TopEntreprisesCard({
    required this.entreprises,
  });

  final List<TopEntreprise> entreprises;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            _TitreSection(
              titre: 'Top entreprises',
              icone:
                  Icons.emoji_events_outlined,
              compteur: entreprises.length,
            ),
            const Divider(height: 28),
            if (entreprises.isEmpty)
              const _MessageVide(
                message:
                    'Aucune entreprise classée pour le moment.',
              )
            else
              ...entreprises.asMap().entries.map(
                (entree) {
                  final position =
                      entree.key + 1;

                  final entreprise =
                      entree.value;

                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 14,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            position.toString(),
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          entreprise.entreprise,
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${entreprise.nombreContrats} '
                          'contrat${entreprise.nombreContrats > 1 ? 's' : ''}',
                        ),
                        trailing: Text(
                          _formatMontantCourt(
                            entreprise
                                .montantTotal,
                          ),
                          textAlign:
                              TextAlign.right,
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ActivitesRecentesCard
    extends StatelessWidget {
  const _ActivitesRecentesCard({
    required this.activites,
  });

  final List<ActiviteRecente> activites;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            _TitreSection(
              titre: 'Activité récente',
              icone:
                  Icons.history_outlined,
              compteur: activites.length,
            ),
            const Divider(height: 28),
            if (activites.isEmpty)
              const _MessageVide(
                message:
                    'Aucune activité récente disponible.',
              )
            else
              ...activites.map(
                (activite) {
                  final reference =
                      activite.reference
                              .trim()
                              .isEmpty
                          ? 'Sans référence'
                          : activite.reference;

                  final titre =
                      activite.titre
                              .trim()
                              .isEmpty
                          ? 'Appel d’offres'
                          : activite.titre;

                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 14,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(
                          16,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .stretch,
                          children: [
                            Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        reference,
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 4,
                                      ),
                                      Text(titre),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                _StatutActiviteChip(
                                  statut:
                                      activite.statut,
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            _DetailActivite(
                              icone: Icons
                                  .account_balance_outlined,
                              texte: activite
                                      .administration
                                      .trim()
                                      .isEmpty
                                  ? 'Administration non renseignée'
                                  : activite
                                      .administration,
                            ),
                            const SizedBox(
                              height: 6,
                            ),
                            _DetailActivite(
                              icone: Icons
                                  .schedule_outlined,
                              texte:
                                  _formatDateHeure(
                                activite
                                    .dateCreation,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _TitreSection extends StatelessWidget {
  const _TitreSection({
    required this.titre,
    required this.icone,
    required this.compteur,
  });

  final String titre;
  final IconData icone;
  final int compteur;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icone,
          color: Theme.of(context)
              .colorScheme
              .primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            titre,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  fontWeight:
                      FontWeight.bold,
                ),
          ),
        ),
        Chip(
          visualDensity:
              VisualDensity.compact,
          label: Text(
            compteur.toString(),
          ),
        ),
      ],
    );
  }
}

class _DetailActivite extends StatelessWidget {
  const _DetailActivite({
    required this.icone,
    required this.texte,
  });

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icone,
          size: 18,
          color: Theme.of(context)
              .colorScheme
              .onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texte,
            style: Theme.of(context)
                .textTheme
                .bodySmall,
          ),
        ),
      ],
    );
  }
}

class _StatutActiviteChip
    extends StatelessWidget {
  const _StatutActiviteChip({
    required this.statut,
  });

  final String statut;

  @override
  Widget build(BuildContext context) {
    final statutNormalise =
        statut.trim().toLowerCase();

    final couleurs =
        Theme.of(context).colorScheme;

    final Color fond;
    final Color texte;

    switch (statutNormalise) {
      case 'publie':
        fond =
            couleurs.primaryContainer;
        texte =
            couleurs.onPrimaryContainer;
        break;

      case 'attribue':
        fond =
            couleurs.tertiaryContainer;
        texte =
            couleurs.onTertiaryContainer;
        break;

      case 'annule':
        fond =
            couleurs.errorContainer;
        texte =
            couleurs.onErrorContainer;
        break;

      default:
        fond = couleurs
            .surfaceContainerHighest;

        texte =
            couleurs.onSurfaceVariant;
    }

    return Chip(
      visualDensity:
          VisualDensity.compact,
      backgroundColor: fond,
      side: BorderSide.none,
      label: Text(
        _libelleStatut(statut),
        style: TextStyle(
          color: texte,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MessageVide extends StatelessWidget {
  const _MessageVide({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 20,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 46,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AvertissementRapports
    extends StatelessWidget {
  const _AvertissementRapports({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context)
          .colorScheme
          .errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color: Theme.of(context)
                  .colorScheme
                  .onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErreurRapports extends StatelessWidget {
  const _ErreurRapports({
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

String _formatMontant(
  double montant,
) {
  return '${NumberFormat.decimalPattern('fr_FR').format(montant)} Ar';
}

String _formatMontantCourt(
  double montant,
) {
  if (montant >= 1000000000) {
    return '${(montant / 1000000000).toStringAsFixed(1)} Md Ar';
  }

  if (montant >= 1000000) {
    return '${(montant / 1000000).toStringAsFixed(1)} M Ar';
  }

  return _formatMontant(montant);
}

String _formatDateHeure(
  DateTime? date,
) {
  if (date == null) {
    return 'Date non renseignée';
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

String _libelleStatut(
  String statut,
) {
  switch (statut.trim().toLowerCase()) {
    case 'brouillon':
      return 'Brouillon';

    case 'publie':
      return 'Publié';

    case 'cloture':
      return 'Clôturé';

    case 'attribue':
      return 'Attribué';

    case 'annule':
      return 'Annulé';

    default:
      final valeur =
          statut.replaceAll('_', ' ').trim();

      return valeur.isEmpty
          ? 'Non défini'
          : valeur;
  }
}

String _libelleTypeMarche(
  String type,
) {
  switch (type.trim().toLowerCase()) {
    case 'travaux':
      return 'Travaux';

    case 'fournitures':
      return 'Fournitures';

    case 'services':
      return 'Services';

    case 'equipements':
      return 'Équipements';

    case 'developpement':
      return 'Développement';

    case 'infrastructure':
      return 'Infrastructure';

    default:
      final valeur =
          type.replaceAll('_', ' ').trim();

      return valeur.isEmpty
          ? 'Non défini'
          : valeur;
  }
}