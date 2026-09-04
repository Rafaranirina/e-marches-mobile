import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/circle_icon.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/fournisseur.dart';
import '../data/fournisseur_repository.dart';
import 'fournisseur_controller.dart';
import 'fournisseurs_page.dart';

/// Page de détail d'un fournisseur : coordonnées complètes,
/// identifiants légaux, statut, et — pour `admin_national`
/// uniquement — historique des changements de statut
/// (`GET /api/entreprises/:id/historique`).
///
/// Les actions d'écriture (modifier, changer le statut) passent par
/// le [FournisseurController] partagé avec [FournisseursPage] (fourni
/// via `ChangeNotifierProvider.value` au moment de la navigation) afin
/// que la liste reste synchronisée au retour sur cette page.
class FournisseurDetailPage
    extends StatefulWidget {
  const FournisseurDetailPage({
    required this.fournisseurId,
    super.key,
  });

  final String fournisseurId;

  @override
  State<FournisseurDetailPage>
      createState() =>
          _FournisseurDetailPageState();
}

class _FournisseurDetailPageState
    extends State<FournisseurDetailPage> {
  final FournisseurRepository
      _repository = FournisseurRepository();

  Fournisseur? _fournisseur;
  bool _chargementDetail = true;
  String? _erreurDetail;

  List<HistoriqueStatutFournisseur>
      _historique = [];
  bool _chargementHistorique = false;
  String? _erreurHistorique;
  bool _historiqueDejaCharge = false;

  @override
  void initState() {
    super.initState();
    _chargerDetail();
  }

  bool get _estAdminNational {
    final role = context
        .read<AuthController>()
        .utilisateur
        ?.role
        .trim()
        .toLowerCase();

    return role == 'admin_national';
  }

  Future<void> _chargerDetail() async {
    setState(() {
      _chargementDetail = true;
      _erreurDetail = null;
    });

    try {
      final fournisseur = await _repository
          .obtenirDetail(
        widget.fournisseurId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _fournisseur = fournisseur;
        _chargementDetail = false;
      });

      if (_estAdminNational &&
          !_historiqueDejaCharge) {
        _chargerHistorique();
      }
    } on FournisseurException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _erreurDetail = error.message;
        _chargementDetail = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _erreurDetail =
            'Impossible de charger ce fournisseur.';
        _chargementDetail = false;
      });
    }
  }

  Future<void> _chargerHistorique() async {
    setState(() {
      _chargementHistorique = true;
      _erreurHistorique = null;
      _historiqueDejaCharge = true;
    });

    try {
      final historique = await _repository
          .obtenirHistorique(
        widget.fournisseurId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _historique = historique;
        _chargementHistorique = false;
      });
    } on FournisseurException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _erreurHistorique = error.message;
        _chargementHistorique = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _erreurHistorique =
            'Impossible de charger l’historique.';
        _chargementHistorique = false;
      });
    }
  }

  Future<void> _modifier() async {
    final fournisseur = _fournisseur;

    if (fournisseur == null) {
      return;
    }

    final donnees = await showDialog<
        DonneesModificationFournisseur>(
      context: context,
      builder: (_) => FournisseurEditDialog(
        fournisseur: fournisseur,
      ),
    );

    if (donnees == null || !mounted) {
      return;
    }

    final controller =
        context.read<FournisseurController>();

    final resultat =
        await controller.modifierFournisseur(
      fournisseur: fournisseur,
      donnees: donnees,
    );

    if (!mounted) {
      return;
    }

    _afficherMessage(
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de modifier le fournisseur.',
      estErreur: resultat == null,
    );

    if (resultat != null) {
      final miseAJour = controller
          .trouverParId(widget.fournisseurId);

      if (miseAJour != null) {
        setState(() {
          _fournisseur = miseAJour;
        });
      }
    }
  }

  Future<void> _changerStatut() async {
    final fournisseur = _fournisseur;

    if (fournisseur == null) {
      return;
    }

    final resultatDialogue = await showDialog<
        StatutFournisseurResultat>(
      context: context,
      builder: (_) => FournisseurStatutDialog(
        fournisseur: fournisseur,
      ),
    );

    if (resultatDialogue == null ||
        !mounted) {
      return;
    }

    final controller =
        context.read<FournisseurController>();

    final resultat =
        await controller.changerStatut(
      fournisseur: fournisseur,
      statut: resultatDialogue.statut,
      motif: resultatDialogue.motif,
    );

    if (!mounted) {
      return;
    }

    _afficherMessage(
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de modifier le statut.',
      estErreur: resultat == null,
    );

    if (resultat != null) {
      final miseAJour = controller
          .trouverParId(widget.fournisseurId);

      if (miseAJour != null) {
        setState(() {
          _fournisseur = miseAJour;
        });
      }

      if (_estAdminNational) {
        _chargerHistorique();
      }
    }
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
    final estAdminNational =
        _estAdminNational;

    final controller = context
        .watch<FournisseurController>();

    final actionEnCours = controller
        .actionEnCoursPour(
      widget.fournisseurId,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Détail du fournisseur',
        ),
        actions: [
          if (estAdminNational &&
              _fournisseur != null)
            IconButton(
              tooltip: 'Modifier les coordonnées',
              onPressed: actionEnCours
                  ? null
                  : _modifier,
              icon: const Icon(
                Icons.edit_outlined,
              ),
            ),
          if (estAdminNational &&
              _fournisseur != null)
            IconButton(
              tooltip: 'Changer le statut',
              onPressed: actionEnCours
                  ? null
                  : _changerStatut,
              icon: const Icon(
                Icons
                    .published_with_changes_outlined,
              ),
            ),
        ],
        bottom: actionEnCours
            ? const PreferredSize(
                preferredSize:
                    Size.fromHeight(3),
                child:
                    LinearProgressIndicator(),
              )
            : null,
      ),
      body: SafeArea(
        child: _buildCorps(
          estAdminNational,
        ),
      ),
    );
  }

  Widget _buildCorps(
    bool estAdminNational,
  ) {
    if (_chargementDetail) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_erreurDetail != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleIcon.erreur(context),
              const SizedBox(height: 20),
              Text(
                _erreurDetail!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _chargerDetail,
                icon: const Icon(
                  Icons.refresh_outlined,
                ),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final fournisseur = _fournisseur;

    if (fournisseur == null) {
      return const Center(
        child: Text(
          'Ce fournisseur est introuvable.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _chargerDetail();
      },
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
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        child: Text(
                          _initiale(
                            fournisseur
                                .raisonSociale,
                          ),
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 14,
                      ),
                      Expanded(
                        child: Text(
                          fournisseur
                              .raisonSociale,
                          style: Theme.of(
                            context,
                          )
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  StatutFournisseurChip(
                    statut: fournisseur
                        .statutValidation,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SectionInformations(
            titre:
                'Identification légale',
            icon: Icons.badge_outlined,
            children: [
              _LigneDetail(
                icon: Icons.badge_outlined,
                label: 'NIF',
                valeur: fournisseur.nif,
              ),
              _LigneDetail(
                icon:
                    Icons.numbers_outlined,
                label: 'STAT',
                valeur: fournisseur.stat,
              ),
              _LigneDetail(
                icon:
                    Icons.numbers_outlined,
                label: 'RCS',
                valeur: fournisseur.rcs,
              ),
              _LigneDetail(
                icon: Icons.person_outline,
                label: 'Représentant légal',
                valeur: fournisseur
                    .representantLegal,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionInformations(
            titre: 'Coordonnées',
            icon: Icons.contact_page_outlined,
            children: [
              _LigneDetail(
                icon: Icons
                    .location_on_outlined,
                label: 'Adresse',
                valeur: fournisseur.adresse,
              ),
              _LigneDetail(
                icon: Icons.phone_outlined,
                label: 'Téléphone',
                valeur:
                    fournisseur.telephone,
              ),
              _LigneDetail(
                icon: Icons.email_outlined,
                label: 'E-mail',
                valeur: fournisseur.email,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionInformations(
            titre: 'Suivi',
            icon: Icons.event_outlined,
            children: [
              _LigneDetail(
                icon: Icons.event_outlined,
                label: 'Créée le',
                valeur: formatDateFournisseur(
                  fournisseur.dateCreation,
                  avecHeure: true,
                ),
              ),
              _LigneDetail(
                icon: Icons
                    .update_outlined,
                label: 'Dernière modification',
                valeur: formatDateFournisseur(
                  fournisseur.dateMaj,
                  avecHeure: true,
                ),
              ),
              if (fournisseur
                      .nombreUtilisateurs !=
                  null)
                _LigneDetail(
                  icon: Icons
                      .people_alt_outlined,
                  label:
                      'Comptes fournisseurs liés',
                  valeur:
                      '${fournisseur.nombreUtilisateurs}',
                ),
              if (fournisseur
                      .nombreSoumissions !=
                  null)
                _LigneDetail(
                  icon: Icons
                      .description_outlined,
                  label: 'Soumissions',
                  valeur:
                      '${fournisseur.nombreSoumissions}',
                ),
              if (fournisseur
                      .nombreContrats !=
                  null)
                _LigneDetail(
                  icon: Icons
                      .assignment_outlined,
                  label: 'Contrats',
                  valeur:
                      '${fournisseur.nombreContrats}',
                ),
            ],
          ),
          if (estAdminNational) ...[
            const SizedBox(height: 12),
            _SectionHistorique(
              historique: _historique,
              chargement:
                  _chargementHistorique,
              erreur: _erreurHistorique,
              onReessayer:
                  _chargerHistorique,
            ),
          ],
        ],
      ),
    );
  }

  static String _initiale(String valeur) {
    final texte = valeur.trim();

    return texte.isEmpty
        ? '?'
        : texte.substring(0, 1).toUpperCase();
  }
}

class _SectionInformations
    extends StatelessWidget {
  const _SectionInformations({
    required this.titre,
    required this.icon,
    required this.children,
  });

  final String titre;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                ),
                const SizedBox(width: 10),
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
              ],
            ),
            const Divider(height: 24),
            for (var i = 0;
                i < children.length;
                i++) ...[
              if (i > 0)
                const SizedBox(height: 12),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _LigneDetail extends StatelessWidget {
  const _LigneDetail({
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
          size: 19,
          color: Theme.of(context)
              .colorScheme
              .primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$label : '
            '${texte.isEmpty ? 'Non renseigné' : texte}',
          ),
        ),
      ],
    );
  }
}

class _SectionHistorique
    extends StatelessWidget {
  const _SectionHistorique({
    required this.historique,
    required this.chargement,
    required this.erreur,
    required this.onReessayer,
  });

  final List<HistoriqueStatutFournisseur>
      historique;
  final bool chargement;
  final String? erreur;
  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history_outlined,
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Historique des statuts',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight:
                            FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (chargement)
              const Center(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (erreur != null)
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(erreur!),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onReessayer,
                    icon: const Icon(
                      Icons.refresh_outlined,
                    ),
                    label: const Text(
                      'Réessayer',
                    ),
                  ),
                ],
              )
            else if (historique.isEmpty)
              const Text(
                'Aucun changement de statut enregistré.',
              )
            else
              for (var i = 0;
                  i < historique.length;
                  i++) ...[
                if (i > 0)
                  const Divider(height: 24),
                _HistoriqueTuile(
                  entree: historique[i],
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _HistoriqueTuile
    extends StatelessWidget {
  const _HistoriqueTuile({
    required this.entree,
  });

  final HistoriqueStatutFournisseur entree;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (entree.ancienStatut != null) ...[
              Text(entree.ancienStatutFormate),
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 6,
                ),
                child: Icon(
                  Icons.arrow_right_alt,
                  size: 18,
                ),
              ),
            ],
            Text(
              entree.nouveauStatutFormate,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Par ${entree.modifieParNomComplet}'
          ' · '
          '${formatDateFournisseur(entree.dateModification, avecHeure: true)}',
          style:
              Theme.of(context).textTheme.bodySmall,
        ),
        if (entree.motif != null &&
            entree.motif!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Motif : ${entree.motif}'),
        ],
      ],
    );
  }
}
