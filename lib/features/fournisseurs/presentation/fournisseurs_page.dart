import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/circle_icon.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/fournisseur.dart';
import 'fournisseur_controller.dart';
import 'fournisseur_detail_page.dart';

class FournisseursPage extends StatelessWidget {
  const FournisseursPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FournisseurController()
        ..charger(),
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
  final TextEditingController
      _rechercheController =
      TextEditingController();

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  Future<void> _creerFournisseur() async {
    final donnees = await showDialog<
        DonneesCreationFournisseur>(
      context: context,
      builder: (_) =>
          const FournisseurFormDialog(),
    );

    if (donnees == null || !mounted) {
      return;
    }

    final controller =
        context.read<FournisseurController>();

    final resultat =
        await controller.creerFournisseur(
      donnees,
    );

    if (!mounted) {
      return;
    }

    _afficherMessage(
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de créer le fournisseur.',
      estErreur: resultat == null,
    );
  }

  Future<void> _modifierFournisseur(
    Fournisseur fournisseur,
  ) async {
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
  }

  Future<void> _changerStatut(
    Fournisseur fournisseur,
  ) async {
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
  }

  Future<void> _validerRapide(
    Fournisseur fournisseur,
  ) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Valider l’entreprise',
          ),
          content: Text(
            'Confirmez-vous la validation de '
            '« ${fournisseur.raisonSociale} » ? '
            'Les comptes fournisseurs en attente '
            'liés à cette entreprise seront '
            'également activés.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext)
                      .pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext)
                      .pop(true),
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );

    if (confirmation != true || !mounted) {
      return;
    }

    final controller =
        context.read<FournisseurController>();

    final resultat =
        await controller.changerStatut(
      fournisseur: fournisseur,
      statut: 'actif',
    );

    if (!mounted) {
      return;
    }

    _afficherMessage(
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de valider cette entreprise.',
      estErreur: resultat == null,
    );
  }

  void _ouvrirDetail(
    Fournisseur fournisseur,
  ) {
    final controller =
        context.read<FournisseurController>();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ChangeNotifierProvider.value(
          value: controller,
          child: FournisseurDetailPage(
            fournisseurId: fournisseur.id,
          ),
        ),
      ),
    );
  }

  void _reinitialiserFiltres() {
    _rechercheController.clear();

    context
        .read<FournisseurController>()
        .reinitialiserFiltres();
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
        context.watch<FournisseurController>();

    final estAdminNational = context
            .watch<AuthController>()
            .utilisateur
            ?.estAdministrateurNational ??
        false;

    final fournisseurs =
        controller.fournisseursFiltres;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fournisseurs'),
        actions: [
          if (estAdminNational)
            IconButton(
              tooltip: 'Créer un fournisseur',
              onPressed: controller.isBusy
                  ? null
                  : _creerFournisseur,
              icon: const Icon(
                Icons.add_business_outlined,
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
                controller.isCreating
            ? const PreferredSize(
                preferredSize:
                    Size.fromHeight(3),
                child:
                    LinearProgressIndicator(),
              )
            : null,
      ),
      floatingActionButton:
          estAdminNational &&
                  !controller.isLoading
              ? FloatingActionButton.extended(
                  onPressed: controller.isBusy
                      ? null
                      : _creerFournisseur,
                  icon: const Icon(
                    Icons.add_business_outlined,
                  ),
                  label: const Text(
                    'Nouveau fournisseur',
                  ),
                )
              : null,
      body: SafeArea(
        child: Column(
          children: [
            _EnteteFournisseurs(
              nombreTotal:
                  controller.nombreTotal,
              nombreActifs:
                  controller.nombreActifs,
              nombreEnAttente:
                  controller.nombreEnAttente,
              nombreSuspendus:
                  controller.nombreSuspendus,
            ),
            _FiltresFournisseurs(
              rechercheController:
                  _rechercheController,
              statutSelectionne:
                  controller.filtreStatut,
              onRecherche:
                  controller.rechercher,
              onStatut:
                  controller.filtrerParStatut,
              onReinitialiser:
                  _reinitialiserFiltres,
            ),
            Expanded(
              child: _buildContenu(
                controller,
                fournisseurs,
                estAdminNational,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenu(
    FournisseurController controller,
    List<Fournisseur> fournisseurs,
    bool estAdminNational,
  ) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.hasError &&
        controller.fournisseurs.isEmpty) {
      return _ErreurFournisseurs(
        message: controller.errorMessage ??
            'Impossible de charger les fournisseurs.',
        onRetry: controller.charger,
      );
    }

    if (controller.fournisseurs.isEmpty) {
      return _FournisseursVides(
        filtreActif: false,
        onActualiser: controller.actualiser,
      );
    }

    if (fournisseurs.isEmpty) {
      return _FournisseursVides(
        filtreActif: true,
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
          110,
        ),
        itemCount: fournisseurs.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final fournisseur =
              fournisseurs[index];

          return _FournisseurCard(
            fournisseur: fournisseur,
            estAdminNational:
                estAdminNational,
            actionEnCours:
                controller.actionEnCoursPour(
              fournisseur.id,
            ),
            onTap: () =>
                _ouvrirDetail(fournisseur),
            onModifier: () {
              _modifierFournisseur(
                fournisseur,
              );
            },
            onChangerStatut: () {
              _changerStatut(fournisseur);
            },
            onValiderRapide: () {
              _validerRapide(fournisseur);
            },
          );
        },
      ),
    );
  }
}

class _EnteteFournisseurs
    extends StatelessWidget {
  const _EnteteFournisseurs({
    required this.nombreTotal,
    required this.nombreActifs,
    required this.nombreEnAttente,
    required this.nombreSuspendus,
  });

  final int nombreTotal;
  final int nombreActifs;
  final int nombreEnAttente;
  final int nombreSuspendus;

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
                      Icons.business_outlined,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '$nombreTotal fournisseur'
                      '${nombreTotal > 1 ? 's' : ''}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
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
                    label: 'Actifs',
                    valeur: nombreActifs,
                    icon:
                        Icons.check_circle_outline,
                  ),
                  _CompteurChip(
                    label: 'En attente',
                    valeur: nombreEnAttente,
                    icon:
                        Icons.hourglass_empty_outlined,
                  ),
                  _CompteurChip(
                    label: 'Suspendus',
                    valeur: nombreSuspendus,
                    icon:
                        Icons.pause_circle_outline,
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
    required this.valeur,
    required this.icon,
  });

  final String label;
  final int valeur;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text('$label : $valeur'),
    );
  }
}

class _FiltresFournisseurs
    extends StatelessWidget {
  const _FiltresFournisseurs({
    required this.rechercheController,
    required this.statutSelectionne,
    required this.onRecherche,
    required this.onStatut,
    required this.onReinitialiser,
  });

  final TextEditingController
      rechercheController;

  final String statutSelectionne;

  final ValueChanged<String> onRecherche;
  final ValueChanged<String> onStatut;
  final VoidCallback onReinitialiser;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        8,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller:
                    rechercheController,
                onChanged: onRecherche,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Rechercher un fournisseur',
                  hintText:
                      'Raison sociale, NIF, STAT ou e-mail',
                  prefixIcon: Icon(
                    Icons.search_outlined,
                  ),
                  border:
                      OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child:
                        DropdownButtonFormField<
                            String>(
                      initialValue:
                          statutSelectionne,
                      decoration:
                          const InputDecoration(
                        labelText: 'Statut',
                        prefixIcon: Icon(
                          Icons.info_outline,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'tous',
                          child: Text(
                            'Tous les statuts',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'actif',
                          child: Text('Actif'),
                        ),
                        DropdownMenuItem(
                          value: 'en_attente',
                          child: Text(
                            'En attente',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'inactif',
                          child:
                              Text('Inactif'),
                        ),
                        DropdownMenuItem(
                          value: 'suspendu',
                          child: Text(
                            'Suspendu',
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          onStatut(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip:
                        'Réinitialiser les filtres',
                    onPressed:
                        onReinitialiser,
                    icon: const Icon(
                      Icons
                          .filter_alt_off_outlined,
                    ),
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

enum _ActionFournisseur {
  modifier,
  statut,
  validerRapide,
}

class _FournisseurCard extends StatelessWidget {
  const _FournisseurCard({
    required this.fournisseur,
    required this.estAdminNational,
    required this.actionEnCours,
    required this.onTap,
    required this.onModifier,
    required this.onChangerStatut,
    required this.onValiderRapide,
  });

  final Fournisseur fournisseur;
  final bool estAdminNational;
  final bool actionEnCours;

  final VoidCallback onTap;
  final VoidCallback onModifier;
  final VoidCallback onChangerStatut;
  final VoidCallback onValiderRapide;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                    radius: 25,
                    child: Text(
                      _initiale(
                        fournisseur
                            .raisonSociale,
                      ),
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
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
                  if (actionEnCours)
                    const Padding(
                      padding:
                          EdgeInsets.all(10),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else if (estAdminNational)
                    PopupMenuButton<
                        _ActionFournisseur>(
                      tooltip: 'Actions',
                      onSelected: (action) {
                        switch (action) {
                          case _ActionFournisseur
                                .modifier:
                            onModifier();
                            break;

                          case _ActionFournisseur
                                .statut:
                            onChangerStatut();
                            break;

                          case _ActionFournisseur
                                .validerRapide:
                            onValiderRapide();
                            break;
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value:
                              _ActionFournisseur
                                  .modifier,
                          child: ListTile(
                            contentPadding:
                                EdgeInsets.zero,
                            leading: Icon(
                              Icons.edit_outlined,
                            ),
                            title: Text(
                              'Modifier les coordonnées',
                            ),
                          ),
                        ),
                        const PopupMenuItem(
                          value:
                              _ActionFournisseur
                                  .statut,
                          child: ListTile(
                            contentPadding:
                                EdgeInsets.zero,
                            leading: Icon(
                              Icons
                                  .published_with_changes_outlined,
                            ),
                            title: Text(
                              'Changer le statut',
                            ),
                          ),
                        ),
                        if (fournisseur
                            .estEnAttente)
                          const PopupMenuItem(
                            value:
                                _ActionFournisseur
                                    .validerRapide,
                            child: ListTile(
                              contentPadding:
                                  EdgeInsets.zero,
                              leading: Icon(
                                Icons
                                    .verified_outlined,
                              ),
                              title: Text(
                                'Valider rapidement',
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatutFournisseurChip(
                    statut: fournisseur
                        .statutValidation,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _InformationFournisseur(
                icon: Icons.badge_outlined,
                label: 'NIF',
                valeur: fournisseur.nif,
              ),
              const SizedBox(height: 10),
              _InformationFournisseur(
                icon: Icons.numbers_outlined,
                label: 'STAT',
                valeur: fournisseur.stat,
              ),
              const SizedBox(height: 10),
              _InformationFournisseur(
                icon: Icons.event_outlined,
                label: 'Date d’inscription',
                valeur: formatDateFournisseur(
                  fournisseur.dateCreation,
                ),
              ),
            ],
          ),
        ),
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

/// Chip de statut d'une entreprise, réutilisé par la page de liste et
/// la page de détail des fournisseurs.
class StatutFournisseurChip
    extends StatelessWidget {
  const StatutFournisseurChip({
    required this.statut,
    super.key,
  });

  final String? statut;

  @override
  Widget build(BuildContext context) {
    final statutNormalise =
        statut?.trim().toLowerCase() ?? '';

    final couleurs =
        Theme.of(context).colorScheme;

    final Color fond;
    final Color texte;
    final IconData icon;

    switch (statutNormalise) {
      case 'actif':
        fond = couleurs.primaryContainer;
        texte = couleurs.onPrimaryContainer;
        icon = Icons.check_circle_outline;
        break;

      case 'en_attente':
        fond = couleurs.secondaryContainer;
        texte =
            couleurs.onSecondaryContainer;
        icon =
            Icons.hourglass_empty_outlined;
        break;

      case 'suspendu':
        fond = couleurs.errorContainer;
        texte = couleurs.onErrorContainer;
        icon = Icons.pause_circle_outline;
        break;

      case 'inactif':
        fond = couleurs.errorContainer;
        texte = couleurs.onErrorContainer;
        icon = Icons.cancel_outlined;
        break;

      default:
        fond =
            couleurs.surfaceContainerHighest;
        texte = couleurs.onSurfaceVariant;
        icon = Icons.block_outlined;
    }

    return Chip(
      backgroundColor: fond,
      side: BorderSide.none,
      avatar: Icon(icon, size: 17, color: texte),
      label: Text(
        formaterStatutFournisseur(statut),
        style: TextStyle(
          color: texte,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Formulaire de création manuelle d'un fournisseur
/// (`POST /api/entreprises`, réservé à `admin_national`). Seule la
/// raison sociale est obligatoire côté backend.
class FournisseurFormDialog
    extends StatefulWidget {
  const FournisseurFormDialog({super.key});

  @override
  State<FournisseurFormDialog>
      createState() =>
          _FournisseurFormDialogState();
}

class _FournisseurFormDialogState
    extends State<FournisseurFormDialog> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController
      _raisonSocialeController =
      TextEditingController();

  final TextEditingController
      _nifController = TextEditingController();

  final TextEditingController
      _statController = TextEditingController();

  final TextEditingController
      _rcsController = TextEditingController();

  final TextEditingController
      _adresseController =
      TextEditingController();

  final TextEditingController
      _telephoneController =
      TextEditingController();

  final TextEditingController
      _emailController =
      TextEditingController();

  final TextEditingController
      _representantLegalController =
      TextEditingController();

  @override
  void dispose() {
    _raisonSocialeController.dispose();
    _nifController.dispose();
    _statController.dispose();
    _rcsController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _representantLegalController
        .dispose();
    super.dispose();
  }

  void _confirmer() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      DonneesCreationFournisseur(
        raisonSociale:
            _raisonSocialeController.text
                .trim(),
        nif: _nifController.text.trim(),
        stat: _statController.text.trim(),
        rcs: _rcsController.text.trim(),
        adresse:
            _adresseController.text.trim(),
        telephone: _telephoneController.text
            .trim(),
        email:
            _emailController.text.trim(),
        representantLegal:
            _representantLegalController
                .text
                .trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Créer un fournisseur',
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode:
                AutovalidateMode
                    .onUserInteraction,
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                TextFormField(
                  controller:
                      _raisonSocialeController,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Raison sociale *',
                    prefixIcon: Icon(
                      Icons.business_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'La raison sociale est obligatoire.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nifController,
                  decoration:
                      const InputDecoration(
                    labelText: 'NIF',
                    prefixIcon: Icon(
                      Icons.badge_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _statController,
                  decoration:
                      const InputDecoration(
                    labelText: 'STAT',
                    prefixIcon: Icon(
                      Icons.numbers_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _rcsController,
                  decoration:
                      const InputDecoration(
                    labelText: 'RCS',
                    prefixIcon: Icon(
                      Icons.numbers_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller:
                      _adresseController,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(
                    labelText: 'Adresse',
                    prefixIcon: Icon(
                      Icons
                          .location_on_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller:
                      _telephoneController,
                  keyboardType:
                      TextInputType.phone,
                  decoration:
                      const InputDecoration(
                    labelText: 'Téléphone',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller:
                      _emailController,
                  keyboardType:
                      TextInputType.emailAddress,
                  autocorrect: false,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Adresse e-mail',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final texte =
                        value?.trim() ?? '';

                    if (texte.isEmpty) {
                      return null;
                    }

                    final valide = RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(texte);

                    return valide
                        ? null
                        : 'L’adresse e-mail est invalide.';
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller:
                      _representantLegalController,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Représentant légal',
                    prefixIcon: Icon(
                      Icons.person_outline,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: _confirmer,
          icon: const Icon(
            Icons.add_business_outlined,
          ),
          label: const Text('Créer'),
        ),
      ],
    );
  }
}

/// Formulaire de modification des coordonnées d'un fournisseur
/// (`PUT /api/entreprises/:id`, réservé à `admin_national`) : seules
/// l'adresse, le téléphone, l'e-mail et le représentant légal restent
/// modifiables après la création — la raison sociale et les
/// identifiants légaux (NIF/STAT/RCS) restent figés.
class FournisseurEditDialog
    extends StatefulWidget {
  const FournisseurEditDialog({
    required this.fournisseur,
    super.key,
  });

  final Fournisseur fournisseur;

  @override
  State<FournisseurEditDialog>
      createState() =>
          _FournisseurEditDialogState();
}

class _FournisseurEditDialogState
    extends State<FournisseurEditDialog> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  late final TextEditingController
      _adresseController;

  late final TextEditingController
      _telephoneController;

  late final TextEditingController
      _emailController;

  late final TextEditingController
      _representantLegalController;

  @override
  void initState() {
    super.initState();

    _adresseController =
        TextEditingController(
      text: widget.fournisseur.adresse ?? '',
    );

    _telephoneController =
        TextEditingController(
      text:
          widget.fournisseur.telephone ?? '',
    );

    _emailController = TextEditingController(
      text: widget.fournisseur.email ?? '',
    );

    _representantLegalController =
        TextEditingController(
      text: widget.fournisseur
              .representantLegal ??
          '',
    );
  }

  @override
  void dispose() {
    _adresseController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _representantLegalController
        .dispose();
    super.dispose();
  }

  void _confirmer() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      DonneesModificationFournisseur(
        adresse:
            _adresseController.text.trim(),
        telephone: _telephoneController.text
            .trim(),
        email:
            _emailController.text.trim(),
        representantLegal:
            _representantLegalController
                .text
                .trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Modifier « '
        '${widget.fournisseur.raisonSociale}'
        ' »',
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode:
                AutovalidateMode
                    .onUserInteraction,
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                TextFormField(
                  controller:
                      _adresseController,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(
                    labelText: 'Adresse',
                    prefixIcon: Icon(
                      Icons
                          .location_on_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller:
                      _telephoneController,
                  keyboardType:
                      TextInputType.phone,
                  decoration:
                      const InputDecoration(
                    labelText: 'Téléphone',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller:
                      _emailController,
                  keyboardType:
                      TextInputType.emailAddress,
                  autocorrect: false,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Adresse e-mail',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final texte =
                        value?.trim() ?? '';

                    if (texte.isEmpty) {
                      return null;
                    }

                    final valide = RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(texte);

                    return valide
                        ? null
                        : 'L’adresse e-mail est invalide.';
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller:
                      _representantLegalController,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Représentant légal',
                    prefixIcon: Icon(
                      Icons.person_outline,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: _confirmer,
          icon: const Icon(
            Icons.save_outlined,
          ),
          label: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

/// Valeur retournée par [FournisseurStatutDialog].
class StatutFournisseurResultat {
  const StatutFournisseurResultat({
    required this.statut,
    this.motif,
  });

  final String statut;
  final String? motif;
}

/// Sélecteur complet de statut d'une entreprise
/// (`PATCH /api/entreprises/:id/statut`, réservé à `admin_national`).
/// Le backend exige un motif pour suspendre ou désactiver une
/// entreprise.
class FournisseurStatutDialog
    extends StatefulWidget {
  const FournisseurStatutDialog({
    required this.fournisseur,
    super.key,
  });

  final Fournisseur fournisseur;

  @override
  State<FournisseurStatutDialog>
      createState() =>
          _FournisseurStatutDialogState();
}

class _FournisseurStatutDialogState
    extends State<FournisseurStatutDialog> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  late String _statut;

  final TextEditingController
      _motifController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    final statutActuel = widget.fournisseur
        .statutValidation
        ?.trim()
        .toLowerCase();

    _statut = Fournisseur.statutsAutorises
            .contains(statutActuel)
        ? statutActuel!
        : 'en_attente';
  }

  @override
  void dispose() {
    _motifController.dispose();
    super.dispose();
  }

  bool get _motifObligatoire =>
      _statut == 'suspendu' ||
      _statut == 'inactif';

  void _confirmer() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      StatutFournisseurResultat(
        statut: _statut,
        motif: _motifController.text
                .trim()
                .isEmpty
            ? null
            : _motifController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Changer le statut'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          autovalidateMode:
              AutovalidateMode
                  .onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.fournisseur
                    .raisonSociale,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _statut,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Nouveau statut',
                  prefixIcon: Icon(
                    Icons
                        .published_with_changes_outlined,
                  ),
                  border:
                      OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'actif',
                    child: Text('Actif'),
                  ),
                  DropdownMenuItem(
                    value: 'en_attente',
                    child:
                        Text('En attente'),
                  ),
                  DropdownMenuItem(
                    value: 'inactif',
                    child: Text('Inactif'),
                  ),
                  DropdownMenuItem(
                    value: 'suspendu',
                    child: Text('Suspendu'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _statut = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _motifController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: _motifObligatoire
                      ? 'Motif *'
                      : 'Motif (optionnel)',
                  helperText:
                      'Obligatoire pour suspendre ou désactiver.',
                  prefixIcon: const Icon(
                    Icons.notes_outlined,
                  ),
                  border:
                      const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_motifObligatoire &&
                      (value ?? '')
                          .trim()
                          .isEmpty) {
                    return 'Un motif est obligatoire pour ce statut.';
                  }

                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _confirmer,
          child: const Text('Confirmer'),
        ),
      ],
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
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FournisseursVides
    extends StatelessWidget {
  const _FournisseursVides({
    required this.filtreActif,
    required this.onActualiser,
  });

  final bool filtreActif;
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
          CircleIcon.neutre(
            context,
            icon: filtreActif
                ? Icons.search_off_outlined
                : Icons.business_outlined,
          ),
          const SizedBox(height: 20),
          Text(
            filtreActif
                ? 'Aucun fournisseur ne correspond aux filtres.'
                : 'Aucun fournisseur enregistré.',
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

String formatDateFournisseur(
  DateTime? date, {
  bool avecHeure = false,
}) {
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

  final base =
      '$jour/$mois/${dateLocale.year}';

  if (!avecHeure) {
    return base;
  }

  final heure = dateLocale.hour
      .toString()
      .padLeft(2, '0');

  final minute = dateLocale.minute
      .toString()
      .padLeft(2, '0');

  return '$base à $heure:$minute';
}
