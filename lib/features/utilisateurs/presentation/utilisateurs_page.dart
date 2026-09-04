import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/circle_icon.dart';
import '../../../shared/widgets/statut_chip.dart';
import '../../administrations/data/administration_marche.dart';
import '../../administrations/data/administration_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../fournisseurs/data/fournisseur.dart';
import '../../fournisseurs/data/fournisseur_repository.dart';
import '../data/utilisateur_gestion.dart';
import 'utilisateur_statut_styles.dart';
import 'utilisateur_controller.dart';

class UtilisateursPage extends StatelessWidget {
  const UtilisateursPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UtilisateurController()
        ..charger(),
      child: const _UtilisateursView(),
    );
  }
}

class _UtilisateursView extends StatefulWidget {
  const _UtilisateursView();

  @override
  State<_UtilisateursView> createState() =>
      _UtilisateursViewState();
}

class _UtilisateursViewState
    extends State<_UtilisateursView> {
  final TextEditingController
      _rechercheController =
      TextEditingController();

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  Future<void> _creerUtilisateur() async {
    final donnees =
        await showDialog<DonneesUtilisateur>(
      context: context,
      builder: (_) =>
          const _UtilisateurFormDialog(),
    );

    if (donnees == null || !mounted) {
      return;
    }

    final controller =
        context.read<UtilisateurController>();

    final resultat =
        await controller.creerUtilisateur(
      donnees,
    );

    if (!mounted) {
      return;
    }

    _afficherMessage(
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de créer le compte.',
      estErreur: resultat == null,
    );
  }

  Future<void> _modifierUtilisateur(
    UtilisateurGestion utilisateur,
  ) async {
    final donnees =
        await showDialog<DonneesUtilisateur>(
      context: context,
      builder: (_) => _UtilisateurFormDialog(
        utilisateur: utilisateur,
      ),
    );

    if (donnees == null || !mounted) {
      return;
    }

    final controller =
        context.read<UtilisateurController>();

    final resultat =
        await controller.modifierUtilisateur(
      utilisateur: utilisateur,
      donnees: donnees,
    );

    if (!mounted) {
      return;
    }

    _afficherMessage(
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de modifier le compte.',
      estErreur: resultat == null,
    );
  }

  Future<void> _changerStatut(
    UtilisateurGestion utilisateur,
  ) async {
    final statut = await showDialog<String>(
      context: context,
      builder: (_) => _StatutUtilisateurDialog(
        utilisateur: utilisateur,
      ),
    );

    if (statut == null || !mounted) {
      return;
    }

    final controller =
        context.read<UtilisateurController>();

    final resultat =
        await controller.changerStatut(
      utilisateur: utilisateur,
      statut: statut,
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

  Future<void> _reinitialiserMotDePasse(
    UtilisateurGestion utilisateur,
  ) async {
    final motDePasse =
        await showDialog<String>(
      context: context,
      builder: (_) =>
          _MotDePasseUtilisateurDialog(
        utilisateur: utilisateur,
      ),
    );

    if (motDePasse == null || !mounted) {
      return;
    }

    final controller =
        context.read<UtilisateurController>();

    final resultat = await controller
        .reinitialiserMotDePasse(
      utilisateur: utilisateur,
      nouveauMotDePasse: motDePasse,
    );

    if (!mounted) {
      return;
    }

    _afficherMessage(
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de réinitialiser le mot de passe.',
      estErreur: resultat == null,
    );
  }

  void _reinitialiserFiltres() {
    _rechercheController.clear();

    context
        .read<UtilisateurController>()
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
        context.watch<UtilisateurController>();

    final compteConnecte = context
        .watch<AuthController>()
        .utilisateur;

    final estAdministrateurNational =
        compteConnecte?.role
                .trim()
                .toLowerCase() ==
            'admin_national';

    if (!estAdministrateurNational) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Utilisateurs',
          ),
        ),
        body: const SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Ce module est réservé à '
                'l’administrateur national.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    final utilisateurs =
        controller.utilisateursFiltres;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestion des utilisateurs',
        ),
        actions: [
          IconButton(
            tooltip: 'Créer un utilisateur',
            onPressed: controller.isBusy
                ? null
                : _creerUtilisateur,
            icon: const Icon(
              Icons.person_add_alt_1_outlined,
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
          controller.isLoading
              ? null
              : FloatingActionButton.extended(
                  onPressed: controller.isBusy
                      ? null
                      : _creerUtilisateur,
                  icon: const Icon(
                    Icons.person_add_alt_1_outlined,
                  ),
                  label: const Text(
                    'Nouvel utilisateur',
                  ),
                ),
      body: SafeArea(
        child: Column(
          children: [
            _EnteteUtilisateurs(
              nombreTotal:
                  controller.nombreTotal,
              nombreActifs:
                  controller.nombreActifs,
              nombreEnAttente:
                  controller.nombreEnAttente,
              nombreSuspendus:
                  controller.nombreSuspendus,
            ),
            _FiltresUtilisateurs(
              rechercheController:
                  _rechercheController,
              roleSelectionne:
                  controller.filtreRole,
              statutSelectionne:
                  controller.filtreStatut,
              onRecherche:
                  controller.rechercher,
              onRole:
                  controller.filtrerParRole,
              onStatut:
                  controller.filtrerParStatut,
              onReinitialiser:
                  _reinitialiserFiltres,
            ),
            Expanded(
              child: _buildContenu(
                controller,
                utilisateurs,
                compteConnecteId:
                    compteConnecte?.id ?? '',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenu(
    UtilisateurController controller,
    List<UtilisateurGestion> utilisateurs, {
    required String compteConnecteId,
  }) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.hasError &&
        controller.utilisateurs.isEmpty) {
      return _ErreurUtilisateurs(
        message: controller.errorMessage ??
            'Impossible de charger les utilisateurs.',
        onRetry: controller.charger,
      );
    }

    if (controller.utilisateurs.isEmpty) {
      return _UtilisateursVides(
        filtreActif: false,
        onActualiser:
            controller.actualiser,
      );
    }

    if (utilisateurs.isEmpty) {
      return _UtilisateursVides(
        filtreActif: true,
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
          110,
        ),
        itemCount: utilisateurs.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final utilisateur =
              utilisateurs[index];

          return _UtilisateurCard(
            utilisateur: utilisateur,
            estCompteConnecte:
                utilisateur.id ==
                    compteConnecteId,
            actionEnCours:
                controller.actionEnCoursPour(
              utilisateur.id,
            ),
            onModifier: () {
              _modifierUtilisateur(
                utilisateur,
              );
            },
            onChangerStatut: () {
              _changerStatut(
                utilisateur,
              );
            },
            onReinitialiserMotDePasse: () {
              _reinitialiserMotDePasse(
                utilisateur,
              );
            },
          );
        },
      ),
    );
  }
}

class _EnteteUtilisateurs
    extends StatelessWidget {
  const _EnteteUtilisateurs({
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
                      Icons.manage_accounts_outlined,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '$nombreTotal utilisateur'
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
      avatar: Icon(
        icon,
        size: 18,
      ),
      label: Text(
        '$label : $valeur',
      ),
    );
  }
}

class _FiltresUtilisateurs
    extends StatelessWidget {
  const _FiltresUtilisateurs({
    required this.rechercheController,
    required this.roleSelectionne,
    required this.statutSelectionne,
    required this.onRecherche,
    required this.onRole,
    required this.onStatut,
    required this.onReinitialiser,
  });

  final TextEditingController
      rechercheController;

  final String roleSelectionne;
  final String statutSelectionne;

  final ValueChanged<String> onRecherche;
  final ValueChanged<String> onRole;
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
                      'Rechercher un utilisateur',
                  hintText:
                      'Nom, e-mail ou téléphone',
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
                          roleSelectionne,
                      decoration:
                          const InputDecoration(
                        labelText: 'Rôle',
                        prefixIcon: Icon(
                          Icons.badge_outlined,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'tous',
                          child: Text(
                            'Tous les rôles',
                          ),
                        ),
                        DropdownMenuItem(
                          value:
                              'admin_national',
                          child: Text(
                            'Administrateur national',
                          ),
                        ),
                        DropdownMenuItem(
                          value:
                              'administration',
                          child: Text(
                            'Administration',
                          ),
                        ),
                        DropdownMenuItem(
                          value:
                              'fournisseur',
                          child: Text(
                            'Fournisseur',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'commission',
                          child: Text(
                            'Commission',
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          onRole(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
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
                          child: Text(
                            'Actif',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'en_attente',
                          child: Text(
                            'En attente',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'inactif',
                          child: Text(
                            'Inactif',
                          ),
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
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment:
                    Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onReinitialiser,
                  icon: const Icon(
                    Icons.filter_alt_off_outlined,
                  ),
                  label: const Text(
                    'Réinitialiser les filtres',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ActionUtilisateur {
  modifier,
  statut,
  motDePasse,
}

class _UtilisateurCard extends StatelessWidget {
  const _UtilisateurCard({
    required this.utilisateur,
    required this.estCompteConnecte,
    required this.actionEnCours,
    required this.onModifier,
    required this.onChangerStatut,
    required this.onReinitialiserMotDePasse,
  });

  final UtilisateurGestion utilisateur;
  final bool estCompteConnecte;
  final bool actionEnCours;

  final VoidCallback onModifier;
  final VoidCallback onChangerStatut;
  final VoidCallback
      onReinitialiserMotDePasse;

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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 25,
                  child: Text(
                    _initiales(
                      utilisateur,
                    ),
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              utilisateur
                                  .nomComplet,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style: Theme.of(
                                context,
                              )
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                            ),
                          ),
                          if (estCompteConnecte) ...[
                            const SizedBox(
                              width: 8,
                            ),
                            const Chip(
                              visualDensity:
                                  VisualDensity
                                      .compact,
                              label: Text(
                                'Votre compte',
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        utilisateur.email,
                      ),
                    ],
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
                else
                  PopupMenuButton<
                      _ActionUtilisateur>(
                    tooltip: 'Actions',
                    onSelected: (action) {
                      switch (action) {
                        case _ActionUtilisateur
                              .modifier:
                          onModifier();
                          break;

                        case _ActionUtilisateur
                              .statut:
                          onChangerStatut();
                          break;

                        case _ActionUtilisateur
                              .motDePasse:
                          onReinitialiserMotDePasse();
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value:
                            _ActionUtilisateur
                                .modifier,
                        child: ListTile(
                          contentPadding:
                              EdgeInsets.zero,
                          leading: Icon(
                            Icons.edit_outlined,
                          ),
                          title: Text(
                            'Modifier',
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value:
                            _ActionUtilisateur
                                .statut,
                        enabled:
                            !estCompteConnecte,
                        child: const ListTile(
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
                      const PopupMenuItem(
                        value:
                            _ActionUtilisateur
                                .motDePasse,
                        child: ListTile(
                          contentPadding:
                              EdgeInsets.zero,
                          leading: Icon(
                            Icons.lock_reset_outlined,
                          ),
                          title: Text(
                            'Réinitialiser le mot de passe',
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
                Chip(
                  avatar: const Icon(
                    Icons.badge_outlined,
                    size: 17,
                  ),
                  label: Text(
                    utilisateur.roleFormate,
                  ),
                ),
                StatutChip(
                  statut: utilisateur.statut,
                  styles: utilisateurStatutStyles,
                ),
                if (utilisateur
                    .doubleAuthActive)
                  const Chip(
                    avatar: Icon(
                      Icons.security_outlined,
                      size: 17,
                    ),
                    label: Text(
                      'Double authentification',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _DetailUtilisateur(
              icon: Icons.phone_outlined,
              label: 'Téléphone',
              valeur:
                  utilisateur.telephone,
            ),
            const SizedBox(height: 10),
            if (utilisateur
                    .administrationId !=
                null)
              _DetailUtilisateur(
                icon: Icons
                    .account_balance_outlined,
                label:
                    'Identifiant administration',
                valeur: utilisateur
                    .administrationId!,
              ),
            if (utilisateur
                    .administrationId !=
                null)
              const SizedBox(height: 10),
            if (utilisateur.entrepriseId !=
                null)
              _DetailUtilisateur(
                icon:
                    Icons.business_outlined,
                label:
                    'Identifiant entreprise',
                valeur:
                    utilisateur.entrepriseId!,
              ),
            if (utilisateur.entrepriseId !=
                null)
              const SizedBox(height: 10),
            _DetailUtilisateur(
              icon: Icons
                  .login_outlined,
              label:
                  'Dernière connexion',
              valeur: _formatDateHeure(
                utilisateur
                    .derniereConnexion,
              ),
            ),
            const SizedBox(height: 10),
            _DetailUtilisateur(
              icon:
                  Icons.event_outlined,
              label: 'Compte créé le',
              valeur: _formatDateHeure(
                utilisateur.dateCreation,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _initiales(
    UtilisateurGestion utilisateur,
  ) {
    final prenom =
        utilisateur.prenom.trim();

    final nom = utilisateur.nom.trim();

    final premiere = prenom.isNotEmpty
        ? prenom[0]
        : '';

    final seconde =
        nom.isNotEmpty ? nom[0] : '';

    final valeur =
        '$premiere$seconde'.toUpperCase();

    return valeur.isEmpty
        ? '?'
        : valeur;
  }
}

class _DetailUtilisateur
    extends StatelessWidget {
  const _DetailUtilisateur({
    required this.icon,
    required this.label,
    required this.valeur,
  });

  final IconData icon;
  final String label;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    final texte = valeur.trim();

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

class _UtilisateurFormDialog
    extends StatefulWidget {
  const _UtilisateurFormDialog({
    this.utilisateur,
  });

  final UtilisateurGestion? utilisateur;

  bool get estModification =>
      utilisateur != null;

  @override
  State<_UtilisateurFormDialog>
      createState() =>
          _UtilisateurFormDialogState();
}

class _UtilisateurFormDialogState
    extends State<_UtilisateurFormDialog> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  late final TextEditingController
      _nomController;

  late final TextEditingController
      _prenomController;

  late final TextEditingController
      _emailController;

  late final TextEditingController
      _telephoneController;

  late final TextEditingController
      _motDePasseController;

  late String _role;
  late String _statut;

  String? _administrationIdSelectionnee;
  String? _entrepriseIdSelectionnee;

  bool _masquerMotDePasse = true;
  bool _chargementReferentiels = true;
  List<AdministrationMarche> _administrations = [];
  List<Fournisseur> _entreprises = [];

  @override
  void initState() {
    super.initState();

    final utilisateur =
        widget.utilisateur;

    _nomController =
        TextEditingController(
      text: utilisateur?.nom ?? '',
    );

    _prenomController =
        TextEditingController(
      text: utilisateur?.prenom ?? '',
    );

    _emailController =
        TextEditingController(
      text: utilisateur?.email ?? '',
    );

    _telephoneController =
        TextEditingController(
      text: utilisateur?.telephone ?? '',
    );

    _motDePasseController =
        TextEditingController();

    _administrationIdSelectionnee =
        utilisateur?.administrationId;

    _entrepriseIdSelectionnee =
        utilisateur?.entrepriseId;

    final roleExistant =
        utilisateur?.role
            .trim()
            .toLowerCase();

    _role = UtilisateurGestion
            .rolesAutorises
            .contains(roleExistant)
        ? roleExistant!
        : 'administration';

    final statutExistant =
        utilisateur?.statut
            .trim()
            .toLowerCase();

    _statut = UtilisateurGestion
            .statutsAutorises
            .contains(statutExistant)
        ? statutExistant!
        : 'actif';

    _chargerReferentiels();
  }

  Future<void> _chargerReferentiels() async {
    try {
      final resultats = await Future.wait([
        AdministrationRepository()
            .listerAdministrations(),
        FournisseurRepository().lister(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _administrations =
            (resultats[0] as ListeAdministrationsResult)
                .administrations;
        _entreprises =
            resultats[1] as List<Fournisseur>;
        _chargementReferentiels = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _chargementReferentiels = false;
      });
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  void _confirmer() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final administrationId =
        _role == 'administration' ||
                _role == 'commission'
            ? _administrationIdSelectionnee
            : null;

    final entrepriseId =
        _role == 'fournisseur'
            ? _entrepriseIdSelectionnee
            : null;

    Navigator.of(context).pop(
      DonneesUtilisateur(
        nom: _nomController.text.trim(),
        prenom:
            _prenomController.text.trim(),
        email:
            _emailController.text.trim(),
        telephone:
            _telephoneController.text.trim(),
        role: _role,
        statut: _statut,
        administrationId:
            administrationId,
        entrepriseId: entrepriseId,
        motDePasse: widget.estModification
            ? null
            : _motDePasseController
                .text
                .trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.estModification
            ? 'Modifier l’utilisateur'
            : 'Créer un utilisateur',
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
                  controller: _nomController,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration:
                      const InputDecoration(
                    labelText: 'Nom *',
                    prefixIcon: Icon(
                      Icons.person_outline,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Le nom est obligatoire.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller:
                      _prenomController,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration:
                      const InputDecoration(
                    labelText: 'Prénom',
                    prefixIcon: Icon(
                      Icons.person_outline,
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
                        'Adresse e-mail *',
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
                      return 'L’adresse e-mail est obligatoire.';
                    }

                    final valide = RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(texte);

                    if (!valide) {
                      return 'L’adresse e-mail est invalide.';
                    }

                    return null;
                  },
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
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration:
                      const InputDecoration(
                    labelText: 'Rôle *',
                    prefixIcon: Icon(
                      Icons.badge_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'admin_national',
                      child: Text(
                        'Administrateur national',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'administration',
                      child: Text(
                        'Administration',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'fournisseur',
                      child: Text(
                        'Fournisseur',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'commission',
                      child: Text(
                        'Commission',
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _role = value;
                    });
                  },
                ),
                if (!widget
                    .estModification) ...[
                  const SizedBox(height: 14),
                  DropdownButtonFormField<
                      String>(
                    initialValue: _statut,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Statut initial *',
                      prefixIcon: Icon(
                        Icons.info_outline,
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
                        child:
                            Text('Inactif'),
                      ),
                      DropdownMenuItem(
                        value: 'suspendu',
                        child:
                            Text('Suspendu'),
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
                ],
                if (_role == 'administration' ||
                    _role == 'commission') ...[
                  const SizedBox(height: 14),
                  _chargementReferentiels
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          initialValue:
                              _administrations.any(
                            (administration) =>
                                administration.id ==
                                _administrationIdSelectionnee,
                          )
                                  ? _administrationIdSelectionnee
                                  : null,
                          isExpanded: true,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Administration',
                            prefixIcon: Icon(
                              Icons
                                  .account_balance_outlined,
                            ),
                            border:
                                OutlineInputBorder(),
                          ),
                          items: [
                            for (final administration
                                in _administrations)
                              DropdownMenuItem(
                                value: administration.id,
                                child: Text(
                                  administration.nom,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _administrationIdSelectionnee =
                                  value;
                            });
                          },
                        ),
                ],
                if (_role == 'fournisseur') ...[
                  const SizedBox(height: 14),
                  _chargementReferentiels
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          initialValue: _entreprises.any(
                            (entreprise) =>
                                entreprise.id ==
                                _entrepriseIdSelectionnee,
                          )
                                  ? _entrepriseIdSelectionnee
                                  : null,
                          isExpanded: true,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Entreprise',
                            prefixIcon: Icon(
                              Icons.business_outlined,
                            ),
                            border:
                                OutlineInputBorder(),
                          ),
                          items: [
                            for (final entreprise
                                in _entreprises)
                              DropdownMenuItem(
                                value: entreprise.id,
                                child: Text(
                                  entreprise.raisonSociale,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _entrepriseIdSelectionnee =
                                  value;
                            });
                          },
                        ),
                ],
                if (!widget
                    .estModification) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller:
                        _motDePasseController,
                    obscureText:
                        _masquerMotDePasse,
                    decoration: InputDecoration(
                      labelText:
                          'Mot de passe *',
                      helperText:
                          'Au moins 8 caractères',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                      ),
                      suffixIcon: IconButton(
                        tooltip:
                            _masquerMotDePasse
                                ? 'Afficher'
                                : 'Masquer',
                        onPressed: () {
                          setState(() {
                            _masquerMotDePasse =
                                !_masquerMotDePasse;
                          });
                        },
                        icon: Icon(
                          _masquerMotDePasse
                              ? Icons
                                  .visibility_outlined
                              : Icons
                                  .visibility_off_outlined,
                        ),
                      ),
                      border:
                          const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final texte =
                          value ?? '';

                      if (texte.length < 8) {
                        return 'Le mot de passe doit contenir au moins 8 caractères.';
                      }

                      return null;
                    },
                  ),
                ],
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
          child: const Text(
            'Annuler',
          ),
        ),
        FilledButton.icon(
          onPressed: _confirmer,
          icon: Icon(
            widget.estModification
                ? Icons.save_outlined
                : Icons
                    .person_add_alt_1_outlined,
          ),
          label: Text(
            widget.estModification
                ? 'Enregistrer'
                : 'Créer',
          ),
        ),
      ],
    );
  }
}

class _StatutUtilisateurDialog
    extends StatefulWidget {
  const _StatutUtilisateurDialog({
    required this.utilisateur,
  });

  final UtilisateurGestion utilisateur;

  @override
  State<_StatutUtilisateurDialog>
      createState() =>
          _StatutUtilisateurDialogState();
}

class _StatutUtilisateurDialogState
    extends State<_StatutUtilisateurDialog> {
  late String _statut;

  @override
  void initState() {
    super.initState();

    final statut =
        widget.utilisateur.statut
            .trim()
            .toLowerCase();

    _statut = UtilisateurGestion
            .statutsAutorises
            .contains(statut)
        ? statut
        : 'actif';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Changer le statut',
      ),
      content: SizedBox(
        width: 430,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.utilisateur.nomComplet,
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
                  child: Text('En attente'),
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Annuler',
          ),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              _statut,
            );
          },
          child: const Text(
            'Confirmer',
          ),
        ),
      ],
    );
  }
}

class _MotDePasseUtilisateurDialog
    extends StatefulWidget {
  const _MotDePasseUtilisateurDialog({
    required this.utilisateur,
  });

  final UtilisateurGestion utilisateur;

  @override
  State<_MotDePasseUtilisateurDialog>
      createState() =>
          _MotDePasseUtilisateurDialogState();
}

class _MotDePasseUtilisateurDialogState
    extends State<
        _MotDePasseUtilisateurDialog> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController
      _motDePasseController =
      TextEditingController();

  final TextEditingController
      _confirmationController =
      TextEditingController();

  bool _masquerMotDePasse = true;

  @override
  void dispose() {
    _motDePasseController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _confirmer() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _motDePasseController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Réinitialiser le mot de passe',
      ),
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
                widget.utilisateur.nomComplet,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller:
                    _motDePasseController,
                obscureText:
                    _masquerMotDePasse,
                decoration: InputDecoration(
                  labelText:
                      'Nouveau mot de passe',
                  helperText:
                      'Au moins 8 caractères',
                  prefixIcon: const Icon(
                    Icons.lock_reset_outlined,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _masquerMotDePasse =
                            !_masquerMotDePasse;
                      });
                    },
                    icon: Icon(
                      _masquerMotDePasse
                          ? Icons
                              .visibility_outlined
                          : Icons
                              .visibility_off_outlined,
                    ),
                  ),
                  border:
                      const OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((value ?? '').length < 8) {
                    return 'Le mot de passe doit contenir au moins 8 caractères.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller:
                    _confirmationController,
                obscureText:
                    _masquerMotDePasse,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Confirmer le mot de passe',
                  prefixIcon: Icon(
                    Icons.lock_outline,
                  ),
                  border:
                      OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value !=
                      _motDePasseController
                          .text) {
                    return 'Les mots de passe ne correspondent pas.';
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
          child: const Text(
            'Annuler',
          ),
        ),
        FilledButton.icon(
          onPressed: _confirmer,
          icon: const Icon(
            Icons.lock_reset_outlined,
          ),
          label: const Text(
            'Réinitialiser',
          ),
        ),
      ],
    );
  }
}

class _ErreurUtilisateurs
    extends StatelessWidget {
  const _ErreurUtilisateurs({
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

class _UtilisateursVides
    extends StatelessWidget {
  const _UtilisateursVides({
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
                ? Icons.person_search_outlined
                : Icons.manage_accounts_outlined,
          ),
          const SizedBox(height: 20),
          Text(
            filtreActif
                ? 'Aucun utilisateur ne correspond aux filtres.'
                : 'Aucun utilisateur disponible.',
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

String _formatDateHeure(
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