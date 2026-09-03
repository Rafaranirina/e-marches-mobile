import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../commissions/presentation/commissions_page.dart';
import '../../evaluations/presentation/evaluations_page.dart';
import '../../soumissions/data/soumission_repository.dart';
import '../../soumissions/presentation/soumission_form_page.dart';
import '../../soumissions/presentation/soumissions_page.dart';
import '../data/appel_offre.dart';
import '../data/appel_offre_repository.dart';
import '../data/appel_offre_transitions.dart';
import 'appel_offre_form_page.dart';

class AppelOffreDetailsPage extends StatefulWidget {
  const AppelOffreDetailsPage({
    required this.appelOffre,
    super.key,
  });

  final AppelOffre appelOffre;

  @override
  State<AppelOffreDetailsPage> createState() =>
      _AppelOffreDetailsPageState();
}

class _AppelOffreDetailsPageState
    extends State<AppelOffreDetailsPage> {
  final AppelOffreRepository _repository =
      AppelOffreRepository();

  late AppelOffre _appelOffre;

  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _appelOffre = widget.appelOffre;
  }

  Future<void> _actualiser() async {
    if (_isBusy) {
      return;
    }

    setState(() {
      _isBusy = true;
    });

    try {
      final appelOffreActualise =
          await _repository.details(
        _appelOffre.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _appelOffre = appelOffreActualise;
      });
    } on AppelOffreException catch (error) {
      if (!mounted) {
        return;
      }

      _afficherMessage(
        error.message,
        estErreur: true,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _afficherMessage(
        'Impossible d’actualiser l’appel d’offres.',
        estErreur: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _modifier() async {
    if (_isBusy) {
      return;
    }

    final resultat =
        await Navigator.of(context)
            .push<AppelOffreActionResult>(
      MaterialPageRoute<AppelOffreActionResult>(
        builder: (_) => AppelOffreFormPage(
          appelOffre: _appelOffre,
        ),
      ),
    );

    if (!mounted || resultat == null) {
      return;
    }

    setState(() {
      _isBusy = true;
    });

    try {
      final appelOffreActualise =
          await _repository.details(
        _appelOffre.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _appelOffre = appelOffreActualise;
      });

      _afficherMessage(
        resultat.message,
      );
    } on AppelOffreException catch (error) {
      if (!mounted) {
        return;
      }

      if (resultat.appelOffre != null) {
        setState(() {
          _appelOffre = resultat.appelOffre!;
        });
      }

      _afficherMessage(
        '${resultat.message} ${error.message}',
        estErreur: true,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      if (resultat.appelOffre != null) {
        setState(() {
          _appelOffre = resultat.appelOffre!;
        });
      }

      _afficherMessage(
        resultat.message,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _publier() async {
    if (_isBusy) {
      return;
    }

    final confirmation =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Publier l’appel d’offres',
          ),
          content: const Text(
            'Après publication, cet appel d’offres ne pourra plus être modifié comme un brouillon. Continuer ?',
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
                Icons.publish_outlined,
              ),
              label: const Text(
                'Publier',
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

    setState(() {
      _isBusy = true;
    });

    try {
      final resultat =
          await _repository.publier(
        _appelOffre.id,
      );

      AppelOffre? appelOffreActualise;

      try {
        appelOffreActualise =
            await _repository.details(
          _appelOffre.id,
        );
      } catch (_) {
        appelOffreActualise =
            resultat.appelOffre;
      }

      if (!mounted) {
        return;
      }

      if (appelOffreActualise != null) {
        setState(() {
          _appelOffre =
              appelOffreActualise!;
        });
      }

      _afficherMessage(
        resultat.message,
      );
    } on AppelOffreException catch (error) {
      if (!mounted) {
        return;
      }

      _afficherMessage(
        error.message,
        estErreur: true,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _afficherMessage(
        'Impossible de publier l’appel d’offres.',
        estErreur: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _changerStatut(
    String statutCible,
  ) async {
    if (_isBusy) {
      return;
    }

    final motifObligatoire =
        AppelOffreTransitions.motifObligatoire(
      statutCible,
    );

    final motifController =
        TextEditingController();

    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                '${AppelOffreTransitions.libelleAction(statutCible)} l’appel d’offres',
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      motifObligatoire
                          ? 'Cette action est définitive. Merci d’indiquer le motif.'
                          : 'Confirmez-vous cette action ?',
                    ),
                    if (motifObligatoire) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller:
                            motifController,
                        maxLines: 3,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Motif *',
                          border:
                              OutlineInputBorder(),
                        ),
                        onChanged: (_) {
                          setDialogState(() {});
                        },
                      ),
                    ],
                  ],
                ),
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
                FilledButton(
                  onPressed: motifObligatoire &&
                          motifController.text
                              .trim()
                              .isEmpty
                      ? null
                      : () {
                          Navigator.of(
                            dialogContext,
                          ).pop(true);
                        },
                  child: Text(
                    AppelOffreTransitions
                        .libelleAction(
                      statutCible,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmation != true || !mounted) {
      return;
    }

    setState(() {
      _isBusy = true;
    });

    try {
      final resultat =
          await _repository.changerStatut(
        id: _appelOffre.id,
        statut: statutCible,
        motif: motifController.text,
      );

      if (!mounted) {
        return;
      }

      if (resultat.appelOffre != null) {
        setState(() {
          _appelOffre = resultat.appelOffre!;
        });
      } else {
        await _actualiser();
      }

      _afficherMessage(
        resultat.message,
      );
    } on AppelOffreException catch (error) {
      if (!mounted) {
        return;
      }

      _afficherMessage(
        error.message,
        estErreur: true,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _afficherMessage(
        'Impossible de changer le statut de l’appel d’offres.',
        estErreur: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _ouvrirSoumissions() async {
    if (_isBusy) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SoumissionsPage(
          appelOffreId:
              _appelOffre.id,
          appelOffreReference:
              _appelOffre.reference,
        ),
      ),
    );
  }

  Future<void> _ouvrirGestionCommissions() async {
    if (_isBusy) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CommissionsPage(
          appelOffreId:
              _appelOffre.id,
          appelOffreTitre:
              _appelOffre.titre,
        ),
      ),
    );
  }

  Future<void> _ouvrirEvaluations() async {
    if (_isBusy) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EvaluationsPage(
          appelOffreId:
              _appelOffre.id,
          appelOffreReference:
              _appelOffre.reference,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _actualiser();
  }

  Future<void> _deposerSoumission() async {
    if (_isBusy) {
      return;
    }

    final resultat =
        await Navigator.of(context)
            .push<SoumissionActionResult>(
      MaterialPageRoute<
          SoumissionActionResult>(
        builder: (_) =>
            SoumissionFormPage(
          appelOffreId:
              _appelOffre.id,
          appelOffreReference:
              _appelOffre.reference,
        ),
      ),
    );

    if (!mounted || resultat == null) {
      return;
    }

    _afficherMessage(
      '${resultat.message} Retrouvez-la dans « Mes soumissions » depuis le tableau de bord pour ajouter vos documents et la transmettre.',
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
    final utilisateur = context
        .watch<AuthController>()
        .utilisateur;

    final role =
        utilisateur?.role
                .trim()
                .toLowerCase() ??
            '';

    final entrepriseId =
        utilisateur?.entrepriseId
                ?.trim() ??
            '';

    final peutAdministrer =
        role == 'admin_national' ||
            role == 'administration';

    final peutVoirSoumissions =
        role == 'admin_national' ||
            role == 'administration' ||
            role == 'commission';

    final estFournisseur =
        role == 'fournisseur';

    final statut =
        _appelOffre.statut
            .trim()
            .toLowerCase();

    final estBrouillon =
        statut == 'brouillon';

    final estPublie =
        statut == 'publie';

    final peutVoirEvaluations =
        peutVoirSoumissions &&
            !estBrouillon;

    final peutVoirCommissions =
        peutVoirSoumissions &&
            !estBrouillon;

    final peutModifier =
        peutAdministrer &&
            estBrouillon;

    final transitionsDisponibles =
        AppelOffreTransitions
            .transitionsDisponibles(
      _appelOffre.statut,
    );

    final peutChangerStatut =
        peutAdministrer &&
            !estBrouillon &&
            transitionsDisponibles.isNotEmpty;

    final dateLimite =
        _appelOffre
            .dateLimiteSoumission
            ?.toLocal();

    final delaiSoumissionOuvert =
        dateLimite == null ||
            dateLimite.isAfter(
              DateTime.now(),
            );

    final peutSoumettre =
        estFournisseur &&
            estPublie &&
            delaiSoumissionOuvert &&
            entrepriseId.isNotEmpty;

    final titre =
        _appelOffre.titre
                .trim()
                .isEmpty
            ? 'Appel d’offres'
            : _appelOffre.titre;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Détail de l’appel d’offres',
        ),
        actions: [
          if (peutVoirSoumissions)
            IconButton(
              tooltip:
                  'Voir les soumissions',
              onPressed: _isBusy
                  ? null
                  : _ouvrirSoumissions,
              icon: const Icon(
                Icons
                    .assignment_turned_in_outlined,
              ),
            ),
          if (peutVoirEvaluations)
            IconButton(
              tooltip:
                  'Évaluations et classement',
              onPressed: _isBusy
                  ? null
                  : _ouvrirEvaluations,
              icon: const Icon(
                Icons.leaderboard_outlined,
              ),
            ),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _isBusy
                ? null
                : _actualiser,
            icon: const Icon(
              Icons.refresh_outlined,
            ),
          ),
        ],
        bottom: _isBusy
            ? const PreferredSize(
                preferredSize:
                    Size.fromHeight(3),
                child:
                    LinearProgressIndicator(),
              )
            : null,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _actualiser,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              120,
            ),
            children: [
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      _StatutChip(
                        statut:
                            _appelOffre
                                .statut,
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Text(
                        titre,
                        style:
                            Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        _appelOffre
                                .reference
                                .trim()
                                .isEmpty
                            ? 'Référence non renseignée'
                            : _appelOffre
                                .reference,
                        style:
                            Theme.of(context)
                                .textTheme
                                .titleSmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                titre:
                    'Informations générales',
                enfants: [
                  _InformationRow(
                    icon: Icons
                        .account_balance_outlined,
                    label:
                        'Administration',
                    valeur: _appelOffre
                        .administrationNom,
                  ),
                  _InformationRow(
                    icon:
                        Icons.short_text,
                    label: 'Sigle',
                    valeur: _appelOffre
                        .administrationSigle,
                  ),
                  _InformationRow(
                    icon: Icons
                        .category_outlined,
                    label: 'Catégorie',
                    valeur: _appelOffre
                        .categorieNom,
                  ),
                  _InformationRow(
                    icon:
                        Icons.work_outline,
                    label:
                        'Type de marché',
                    valeur:
                        _libelleTypeMarche(
                      _appelOffre
                          .typeMarche,
                    ),
                  ),
                  _InformationRow(
                    icon: Icons
                        .payments_outlined,
                    label:
                        'Montant estimé',
                    valeur:
                        _formatMontant(
                      _appelOffre
                          .montantEstime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                titre: 'Calendrier',
                enfants: [
                  _InformationRow(
                    icon: Icons
                        .publish_outlined,
                    label:
                        'Date de publication',
                    valeur: _formatDate(
                      _appelOffre
                          .datePublication,
                    ),
                  ),
                  _InformationRow(
                    icon: Icons
                        .event_busy_outlined,
                    label:
                        'Date limite de soumission',
                    valeur: _formatDate(
                      _appelOffre
                          .dateLimiteSoumission,
                    ),
                  ),
                  _InformationRow(
                    icon: Icons
                        .event_available_outlined,
                    label:
                        'Ouverture des plis',
                    valeur: _formatDate(
                      _appelOffre
                          .dateOuverturePlis,
                    ),
                  ),
                  _InformationRow(
                    icon: Icons
                        .add_circle_outline,
                    label:
                        'Date de création',
                    valeur: _formatDate(
                      _appelOffre
                          .dateCreation,
                    ),
                  ),
                  _InformationRow(
                    icon: Icons
                        .update_outlined,
                    label:
                        'Dernière modification',
                    valeur: _formatDate(
                      _appelOffre.dateMaj,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                titre: 'Description',
                enfants: [
                  Text(
                    _valeurOuDefaut(
                      _appelOffre
                          .description,
                      defaut:
                          'Aucune description renseignée.',
                    ),
                    style:
                        Theme.of(context)
                            .textTheme
                            .bodyLarge,
                  ),
                ],
              ),
              if (peutVoirSoumissions) ...[
                const SizedBox(
                  height: 12,
                ),
                Card(
                  clipBehavior:
                      Clip.antiAlias,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    leading:
                        const CircleAvatar(
                      child: Icon(
                        Icons
                            .assignment_turned_in_outlined,
                      ),
                    ),
                    title: const Text(
                      'Soumissions reçues',
                    ),
                    subtitle: const Text(
                      'Consulter et traiter les soumissions de cet appel d’offres',
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: _isBusy
                        ? null
                        : _ouvrirSoumissions,
                  ),
                ),
              ],
              if (peutVoirCommissions) ...[
                const SizedBox(
                  height: 12,
                ),
                Card(
                  clipBehavior:
                      Clip.antiAlias,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    leading:
                        const CircleAvatar(
                      child: Icon(
                        Icons.groups_outlined,
                      ),
                    ),
                    title: const Text(
                      'Commissions',
                    ),
                    subtitle: const Text(
                      'Consulter les commissions et leurs membres',
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: _isBusy
                        ? null
                        : _ouvrirGestionCommissions,
                  ),
                ),
              ],
              if (peutVoirEvaluations) ...[
                const SizedBox(
                  height: 12,
                ),
                Card(
                  clipBehavior:
                      Clip.antiAlias,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    leading:
                        const CircleAvatar(
                      child: Icon(
                        Icons
                            .leaderboard_outlined,
                      ),
                    ),
                    title: const Text(
                      'Évaluations et classement',
                    ),
                    subtitle: const Text(
                      'Noter les soumissions, consulter le classement et attribuer le marché',
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: _isBusy
                        ? null
                        : _ouvrirEvaluations,
                  ),
                ),
              ],
              if (peutAdministrer &&
                  !estBrouillon &&
                  transitionsDisponibles
                      .isEmpty) ...[
                const SizedBox(
                  height: 12,
                ),
                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets
                            .all(16),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Text(
                            'Cet appel d’offres est dans un statut définitif : aucune action supplémentaire n’est disponible.',
                            style: Theme.of(
                              context,
                            )
                                .textTheme
                                .bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (estFournisseur &&
                  entrepriseId.isEmpty) ...[
                const SizedBox(
                  height: 12,
                ),
                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets
                            .all(16),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Icon(
                          Icons
                              .warning_amber_outlined,
                          color:
                              Theme.of(context)
                                  .colorScheme
                                  .error,
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        const Expanded(
                          child: Text(
                            'Aucune entreprise n’est associée à votre compte fournisseur. Le dépôt d’une soumission est indisponible.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (estFournisseur &&
                  estPublie &&
                  !delaiSoumissionOuvert) ...[
                const SizedBox(
                  height: 12,
                ),
                const Card(
                  child: Padding(
                    padding:
                        EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Icon(
                          Icons
                              .event_busy_outlined,
                        ),
                        SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Text(
                            'La date limite de soumission est dépassée.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: peutModifier
          ? SafeArea(
              child: Material(
                elevation: 12,
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child:
                            OutlinedButton
                                .icon(
                          onPressed: _isBusy
                              ? null
                              : _modifier,
                          icon: const Icon(
                            Icons
                                .edit_outlined,
                          ),
                          label:
                              const Text(
                            'Modifier',
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child:
                            FilledButton
                                .icon(
                          onPressed: _isBusy
                              ? null
                              : _publier,
                          icon: const Icon(
                            Icons
                                .publish_outlined,
                          ),
                          label:
                              const Text(
                            'Publier',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : peutChangerStatut
              ? SafeArea(
                  child: Material(
                    elevation: 12,
                    child: Padding(
                      padding:
                          const EdgeInsets
                              .all(16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment:
                            WrapAlignment
                                .end,
                        children: [
                          for (final statutCible
                              in transitionsDisponibles)
                            OutlinedButton.icon(
                              onPressed: _isBusy
                                  ? null
                                  : () =>
                                      _changerStatut(
                                        statutCible,
                                      ),
                              icon: Icon(
                                statutCible ==
                                        'annule'
                                    ? Icons
                                        .cancel_outlined
                                    : Icons
                                        .arrow_forward,
                              ),
                              label: Text(
                                AppelOffreTransitions
                                    .libelleAction(
                                  statutCible,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                )
              : peutSoumettre
                  ? SafeArea(
                      child: Material(
                        elevation: 12,
                        child: Padding(
                          padding:
                              const EdgeInsets
                                  .all(16),
                          child:
                              FilledButton.icon(
                            onPressed: _isBusy
                                ? null
                                : _deposerSoumission,
                            icon: const Icon(
                              Icons
                                  .send_outlined,
                            ),
                            label: const Text(
                              'Déposer une soumission',
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
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

    final localDate =
        date.toLocal();

    final jour = localDate.day
        .toString()
        .padLeft(2, '0');

    final mois = localDate.month
        .toString()
        .padLeft(2, '0');

    final heure = localDate.hour
        .toString()
        .padLeft(2, '0');

    final minute = localDate.minute
        .toString()
        .padLeft(2, '0');

    return '$jour/$mois/${localDate.year} à $heure:$minute';
  }

  static String _valeurOuDefaut(
    String? valeur, {
    String defaut = 'Non renseigné',
  }) {
    final texte =
        valeur?.trim() ?? '';

    return texte.isEmpty
        ? defaut
        : texte;
  }

  static String _libelleTypeMarche(
    String type,
  ) {
    switch (
        type.trim().toLowerCase()) {
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
        return type;
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.titre,
    required this.enfants,
  });

  final String titre;
  final List<Widget> enfants;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Text(
              titre,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
            ),
            const Divider(height: 28),
            ...enfants,
          ],
        ),
      ),
    );
  }
}

class _InformationRow
    extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.label,
    required this.valeur,
  });

  final IconData icon;
  final String label;
  final String? valeur;

  @override
  Widget build(BuildContext context) {
    final texte =
        valeur?.trim() ?? '';

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 16,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color:
                Theme.of(context)
                    .colorScheme
                    .primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  label,
                  style:
                      Theme.of(context)
                          .textTheme
                          .labelLarge,
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  texte.isEmpty
                      ? 'Non renseigné'
                      : texte,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatutChip
    extends StatelessWidget {
  const _StatutChip({
    required this.statut,
  });

  final String statut;

  @override
  Widget build(BuildContext context) {
    final couleur =
        Theme.of(context)
            .colorScheme;

    final statutNormalise =
        statut.trim().toLowerCase();

    final String texte;
    final Color fond;
    final Color premierPlan;
    final IconData icone;

    switch (statutNormalise) {
      case 'brouillon':
        texte = 'Brouillon';
        fond =
            couleur.secondaryContainer;
        premierPlan =
            couleur.onSecondaryContainer;
        icone =
            Icons.edit_note_outlined;
        break;

      case 'publie':
        texte = 'Publié';
        fond =
            couleur.primaryContainer;
        premierPlan =
            couleur.onPrimaryContainer;
        icone =
            Icons.public_outlined;
        break;

      case 'cloture':
        texte = 'Clôturé';
        fond =
            couleur.tertiaryContainer;
        premierPlan =
            couleur.onTertiaryContainer;
        icone =
            Icons.event_busy_outlined;
        break;

      case 'en_evaluation':
        texte = 'En évaluation';
        fond =
            couleur.tertiaryContainer;
        premierPlan =
            couleur.onTertiaryContainer;
        icone =
            Icons.leaderboard_outlined;
        break;

      case 'attribue':
        texte = 'Attribué';
        fond =
            couleur.primaryContainer;
        premierPlan =
            couleur.onPrimaryContainer;
        icone =
            Icons.verified_outlined;
        break;

      case 'infructueux':
        texte = 'Infructueux';
        fond =
            couleur.errorContainer;
        premierPlan =
            couleur.onErrorContainer;
        icone =
            Icons.block_outlined;
        break;

      case 'annule':
        texte = 'Annulé';
        fond =
            couleur.errorContainer;
        premierPlan =
            couleur.onErrorContainer;
        icone =
            Icons.cancel_outlined;
        break;

      default:
        texte = statut.trim().isEmpty
            ? 'Non défini'
            : statut.replaceAll(
                '_',
                ' ',
              );

        fond = couleur
            .surfaceContainerHighest;

        premierPlan =
            couleur.onSurfaceVariant;

        icone =
            Icons.info_outline;
    }

    return Align(
      alignment:
          Alignment.centerLeft,
      child: Chip(
        backgroundColor: fond,
        side: BorderSide.none,
        avatar: Icon(
          icone,
          size: 18,
          color: premierPlan,
        ),
        label: Text(
          texte,
          style: TextStyle(
            color: premierPlan,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }
}