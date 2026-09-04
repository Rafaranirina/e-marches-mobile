import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/circle_icon.dart';
import '../../../shared/widgets/statut_chip.dart';
import '../../appels_offres/presentation/appel_offre_statut_styles.dart';
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
          _TransparenceCard(
            transparence:
                controller.transparence,
          ),
          const SizedBox(height: 16),
          _ActiviteMensuelleCard(
            activite: controller
                .activiteMensuelle,
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

class _TransparenceCard extends StatelessWidget {
  const _TransparenceCard({
    required this.transparence,
  });

  final IndicateursTransparence transparence;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const _TitreSectionSansCompteur(
              titre:
                  'Indicateurs de transparence',
              icone:
                  Icons.policy_outlined,
            ),
            const Divider(height: 28),
            LayoutBuilder(
              builder:
                  (context, contraintes) {
                final largeur =
                    contraintes.maxWidth;

                final largeurCarte =
                    largeur >= 700
                        ? (largeur - 24) / 3
                        : largeur >= 480
                            ? (largeur - 12) /
                                2
                            : largeur;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: largeurCarte,
                      child: _IndicateurTile(
                        titre:
                            'Délai moyen d’attribution',
                        valeur: _formatJours(
                          transparence
                              .delaiMoyenAttributionJours,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: largeurCarte,
                      child: _IndicateurTile(
                        titre:
                            'Marchés attribués',
                        valeur: transparence
                            .nombreMarchesAttribues
                            .toString(),
                      ),
                    ),
                    SizedBox(
                      width: largeurCarte,
                      child: _IndicateurTile(
                        titre:
                            'Offres par marché en moyenne',
                        valeur: _formatNombre(
                          transparence
                              .moyenneSoumissionsParMarche,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: largeurCarte,
                      child: _IndicateurTile(
                        titre:
                            'Taux d’infructueux',
                        valeur: _formatPourcent(
                          transparence
                              .tauxInfructueuxPourcent,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: largeurCarte,
                      child: _IndicateurTile(
                        titre:
                            'Taux de mono-offre',
                        valeur: _formatPourcent(
                          transparence
                              .tauxMonoOffrePourcent,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: largeurCarte,
                      child: _IndicateurTile(
                        titre:
                            'Marchés infructueux',
                        valeur: transparence
                            .nombreInfructueux
                            .toString(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicateurTile extends StatelessWidget {
  const _IndicateurTile({
    required this.titre,
    required this.valeur,
  });

  final String titre;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              valeur,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              titre,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiviteMensuelleCard
    extends StatelessWidget {
  const _ActiviteMensuelleCard({
    required this.activite,
  });

  final List<ActiviteMensuelle> activite;

  static const _hauteurMaximaleBarre = 130.0;
  static const _hauteurMinimaleBarre = 4.0;

  @override
  Widget build(BuildContext context) {
    final maximum = activite.isEmpty
        ? 0
        : activite
            .expand(
              (element) => [
                element.publiees,
                element.cloturees,
              ],
            )
            .reduce(
              (valeurA, valeurB) =>
                  valeurA > valeurB
                      ? valeurA
                      : valeurB,
            );

    final couleurs =
        Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            _TitreSection(
              titre:
                  'Activité des 12 derniers mois',
              icone:
                  Icons.show_chart_outlined,
              compteur: activite.length,
            ),
            const Divider(height: 28),
            if (activite.isEmpty)
              const _MessageVide(
                message:
                    'Aucune donnée d’activité mensuelle disponible.',
              )
            else ...[
              SizedBox(
                height: 190,
                child: SingleChildScrollView(
                  scrollDirection:
                      Axis.horizontal,
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .end,
                    children: activite
                        .map(
                          (mois) => Padding(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 6,
                            ),
                            child: Column(
                              mainAxisSize:
                                  MainAxisSize
                                      .min,
                              children: [
                                Row(
                                  mainAxisSize:
                                      MainAxisSize
                                          .min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .end,
                                  children: [
                                    _BarreActivite(
                                      hauteur:
                                          _hauteurBarre(
                                        mois.publiees,
                                        maximum,
                                      ),
                                      couleur:
                                          couleurs
                                              .primary,
                                    ),
                                    const SizedBox(
                                      width: 4,
                                    ),
                                    _BarreActivite(
                                      hauteur:
                                          _hauteurBarre(
                                        mois.cloturees,
                                        maximum,
                                      ),
                                      couleur:
                                          couleurs
                                              .tertiary,
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                Text(
                                  _libelleMois(
                                    mois
                                        .moisDebut,
                                  ),
                                  textAlign:
                                      TextAlign
                                          .center,
                                  style: Theme.of(
                                    context,
                                  )
                                      .textTheme
                                      .bodySmall,
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _LegendeActivite(
                    couleur:
                        couleurs.primary,
                    texte: 'Publiés',
                  ),
                  const SizedBox(width: 20),
                  _LegendeActivite(
                    couleur:
                        couleurs.tertiary,
                    texte: 'Clôturés',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _hauteurBarre(
    int valeur,
    int maximum,
  ) {
    if (maximum <= 0 || valeur <= 0) {
      return _hauteurMinimaleBarre;
    }

    final hauteur =
        (valeur / maximum) *
            _hauteurMaximaleBarre;

    return hauteur < _hauteurMinimaleBarre
        ? _hauteurMinimaleBarre
        : hauteur;
  }
}

class _BarreActivite extends StatelessWidget {
  const _BarreActivite({
    required this.hauteur,
    required this.couleur,
  });

  final double hauteur;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: hauteur.round().toString(),
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 300,
        ),
        width: 14,
        height: hauteur,
        decoration: BoxDecoration(
          color: couleur,
          borderRadius:
              BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _LegendeActivite extends StatelessWidget {
  const _LegendeActivite({
    required this.couleur,
    required this.texte,
  });

  final Color couleur;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: couleur,
            borderRadius:
                BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          texte,
          style: Theme.of(context)
              .textTheme
              .bodySmall,
        ),
      ],
    );
  }
}

class _TitreSectionSansCompteur
    extends StatelessWidget {
  const _TitreSectionSansCompteur({
    required this.titre,
    required this.icone,
  });

  final String titre;
  final IconData icone;

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
      ],
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
                                StatutChip(
                                  statut: activite.statut,
                                  styles: appelOffreStatutStyles,
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

String _formatJours(
  double? valeur,
) {
  if (valeur == null) {
    return '—';
  }

  final texte = valeur % 1 == 0
      ? valeur.toStringAsFixed(0)
      : valeur.toStringAsFixed(1);

  return '$texte j';
}

String _formatNombre(
  double? valeur,
) {
  if (valeur == null) {
    return '—';
  }

  return valeur % 1 == 0
      ? valeur.toStringAsFixed(0)
      : valeur.toStringAsFixed(1);
}

String _formatPourcent(
  double? valeur,
) {
  if (valeur == null) {
    return '—';
  }

  final texte = valeur % 1 == 0
      ? valeur.toStringAsFixed(0)
      : valeur.toStringAsFixed(1);

  return '$texte %';
}

const _libellesMois = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

String _libelleMois(
  DateTime date,
) {
  final dateLocale = date.toLocal();

  final indexMois =
      dateLocale.month - 1;

  final libelle = indexMois >= 0 &&
          indexMois < _libellesMois.length
      ? _libellesMois[indexMois]
      : '';

  return '$libelle\n${dateLocale.year}';
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