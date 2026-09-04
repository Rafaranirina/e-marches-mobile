import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/actif_statut_styles.dart';
import '../../../shared/widgets/circle_icon.dart';
import '../../../shared/widgets/statut_chip.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/administration_marche.dart';
import 'administration_controller.dart';
import 'administration_detail_page.dart';

class AdministrationsPage extends StatelessWidget {
  const AdministrationsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdministrationController()
        ..charger(),
      child: const _AdministrationsView(),
    );
  }
}

class _AdministrationsView extends StatefulWidget {
  const _AdministrationsView();

  @override
  State<_AdministrationsView> createState() =>
      _AdministrationsViewState();
}

class _AdministrationsViewState
    extends State<_AdministrationsView> {
  final TextEditingController
      _rechercheController =
      TextEditingController();

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  Future<void> _creerAdministration() async {
    final donnees =
        await showDialog<DonneesAdministration>(
      context: context,
      builder: (_) =>
          const _AdministrationFormDialog(),
    );

    if (donnees == null || !mounted) {
      return;
    }

    final controller =
        context.read<AdministrationController>();

    final resultat =
        await controller.creerAdministration(
      donnees,
    );

    if (!mounted) {
      return;
    }

    _afficherMessage(
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de créer l’administration.',
      estErreur: resultat == null,
    );
  }

  Future<void> _modifierAdministration(
    AdministrationMarche administration,
  ) async {
    final donnees =
        await showDialog<DonneesAdministration>(
      context: context,
      builder: (_) => _AdministrationFormDialog(
        administration: administration,
      ),
    );

    if (donnees == null || !mounted) {
      return;
    }

    final controller =
        context.read<AdministrationController>();

    final resultat =
        await controller.modifierAdministration(
      administration: administration,
      donnees: donnees,
    );

    if (!mounted) {
      return;
    }

    _afficherMessage(
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de modifier l’administration.',
      estErreur: resultat == null,
    );
  }

  Future<void> _changerStatut(
    AdministrationMarche administration,
  ) async {
    final nouveauStatut = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _StatutAdministrationDialog(
        administration: administration,
      ),
    );

    if (nouveauStatut == null || !mounted) {
      return;
    }

    final controller =
        context.read<AdministrationController>();

    final resultat =
        await controller.changerStatut(
      administration: administration,
      actif: nouveauStatut,
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

  void _ouvrirDetail(
    AdministrationMarche administration,
  ) {
    final controller =
        context.read<AdministrationController>();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ChangeNotifierProvider.value(
          value: controller,
          child: AdministrationDetailPage(
            administrationId:
                administration.id,
          ),
        ),
      ),
    );
  }

  void _reinitialiserRecherche() {
    _rechercheController.clear();

    context
        .read<AdministrationController>()
        .reinitialiserRecherche();
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
        context.watch<AdministrationController>();

    final utilisateur = context
        .watch<AuthController>()
        .utilisateur;

    final estAdministrateurNational =
        utilisateur?.role
                .trim()
                .toLowerCase() ==
            'admin_national';

    final administrations =
        controller.administrationsFiltrees;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Administrations',
        ),
        actions: [
          if (estAdministrateurNational)
            IconButton(
              tooltip:
                  'Créer une administration',
              onPressed: controller.isBusy
                  ? null
                  : _creerAdministration,
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
          estAdministrateurNational &&
                  !controller.isLoading
              ? FloatingActionButton.extended(
                  onPressed:
                      controller.isBusy
                          ? null
                          : _creerAdministration,
                  icon: const Icon(
                    Icons.add_business_outlined,
                  ),
                  label: const Text(
                    'Nouvelle administration',
                  ),
                )
              : null,
      body: SafeArea(
        child: Column(
          children: [
            _EnteteAdministrations(
              nombreTotal:
                  controller.nombreTotal,
              nombreAvecSigle:
                  controller.nombreAvecSigle,
              nombreAvecCoordonnees:
                  controller
                      .nombreAvecCoordonnees,
            ),
            _RechercheAdministrations(
              controller:
                  _rechercheController,
              onChanged:
                  controller.rechercher,
              onClear:
                  _reinitialiserRecherche,
            ),
            Expanded(
              child: _buildContenu(
                controller,
                administrations,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenu(
    AdministrationController controller,
    List<AdministrationMarche>
        administrations,
  ) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.hasError &&
        controller.administrations.isEmpty) {
      return _ErreurAdministrations(
        message: controller.errorMessage ??
            'Impossible de charger les administrations.',
        onRetry: controller.charger,
      );
    }

    if (controller.administrations.isEmpty) {
      return _AdministrationsVides(
        filtreActif: false,
        onActualiser:
            controller.actualiser,
      );
    }

    if (administrations.isEmpty) {
      return _AdministrationsVides(
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
        itemCount: administrations.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final administration =
              administrations[index];

          return _AdministrationCard(
            administration: administration,
            actionEnCours:
                controller.actionEnCoursPour(
              administration.id,
            ),
            onTap: () {
              _ouvrirDetail(
                administration,
              );
            },
            onModifier: () {
              _modifierAdministration(
                administration,
              );
            },
            onChangerStatut: () {
              _changerStatut(
                administration,
              );
            },
          );
        },
      ),
    );
  }
}

class _EnteteAdministrations
    extends StatelessWidget {
  const _EnteteAdministrations({
    required this.nombreTotal,
    required this.nombreAvecSigle,
    required this.nombreAvecCoordonnees,
  });

  final int nombreTotal;
  final int nombreAvecSigle;
  final int nombreAvecCoordonnees;

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
                          .account_balance_outlined,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '$nombreTotal administration'
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
                    icon:
                        Icons.short_text_outlined,
                    label: 'Avec sigle',
                    valeur: nombreAvecSigle,
                  ),
                  _CompteurChip(
                    icon:
                        Icons.contact_phone_outlined,
                    label: 'Avec coordonnées',
                    valeur:
                        nombreAvecCoordonnees,
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
    required this.icon,
    required this.label,
    required this.valeur,
  });

  final IconData icon;
  final String label;
  final int valeur;

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

class _RechercheAdministrations
    extends StatelessWidget {
  const _RechercheAdministrations({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        8,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText:
              'Rechercher une administration',
          hintText:
              'Nom, sigle, type, e-mail ou téléphone',
          prefixIcon: const Icon(
            Icons.search_outlined,
          ),
          suffixIcon: IconButton(
            tooltip:
                'Effacer la recherche',
            onPressed: onClear,
            icon: const Icon(
              Icons.clear_outlined,
            ),
          ),
          border:
              const OutlineInputBorder(),
        ),
      ),
    );
  }
}

enum _ActionAdministration {
  modifier,
  statut,
}

class _AdministrationCard
    extends StatelessWidget {
  const _AdministrationCard({
    required this.administration,
    required this.actionEnCours,
    required this.onTap,
    required this.onModifier,
    required this.onChangerStatut,
  });

  final AdministrationMarche administration;
  final bool actionEnCours;

  final VoidCallback onTap;
  final VoidCallback onModifier;
  final VoidCallback onChangerStatut;

  @override
  Widget build(BuildContext context) {
    final sigle =
        administration.sigle.trim();

    final typeEntite =
        administration.typeEntite.trim();

    return Card(
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
                  radius: 26,
                  child: Text(
                    _initiale(
                      administration,
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
                      Text(
                        administration.nom,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                      ),
                      if (sigle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(sigle),
                      ],
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
                      _ActionAdministration>(
                    tooltip: 'Actions',
                    onSelected: (action) {
                      switch (action) {
                        case _ActionAdministration
                              .modifier:
                          onModifier();
                          break;

                        case _ActionAdministration
                              .statut:
                          onChangerStatut();
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value:
                            _ActionAdministration
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
                            _ActionAdministration
                                .statut,
                        child: ListTile(
                          contentPadding:
                              EdgeInsets.zero,
                          leading: Icon(
                            administration
                                    .actif
                                ? Icons
                                    .block_outlined
                                : Icons
                                    .check_circle_outline,
                          ),
                          title: Text(
                            administration
                                    .actif
                                ? 'Désactiver'
                                : 'Activer',
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
                if (typeEntite.isNotEmpty)
                  Chip(
                    avatar: const Icon(
                      Icons
                          .account_tree_outlined,
                      size: 17,
                    ),
                    label: Text(
                      administration
                          .typeEntiteFormate,
                    ),
                  ),
                StatutChip(
                  statut: cleActifStatut(administration.actif),
                  styles: actifStatutStyles,
                ),
              ],
            ),
            if (administration
                .possedeCoordonnees) ...[
              const Divider(height: 28),
              if (administration.adresse
                  .trim()
                  .isNotEmpty)
                _DetailAdministration(
                  icon:
                      Icons.location_on_outlined,
                  label: 'Adresse',
                  valeur:
                      administration.adresse,
                ),
              if (administration.adresse
                      .trim()
                      .isNotEmpty &&
                  administration.telephone
                      .trim()
                      .isNotEmpty)
                const SizedBox(height: 10),
              if (administration.telephone
                  .trim()
                  .isNotEmpty)
                _DetailAdministration(
                  icon:
                      Icons.phone_outlined,
                  label: 'Téléphone',
                  valeur:
                      administration.telephone,
                ),
              if (administration.telephone
                      .trim()
                      .isNotEmpty &&
                  administration.email
                      .trim()
                      .isNotEmpty)
                const SizedBox(height: 10),
              if (administration.email
                  .trim()
                  .isNotEmpty)
                _DetailAdministration(
                  icon:
                      Icons.email_outlined,
                  label: 'E-mail',
                  valeur:
                      administration.email,
                ),
            ],
          ],
        ),
        ),
      ),
    );
  }

  static String _initiale(
    AdministrationMarche administration,
  ) {
    final sigle =
        administration.sigle.trim();

    if (sigle.isNotEmpty) {
      return sigle.length >= 2
          ? sigle.substring(0, 2).toUpperCase()
          : sigle.toUpperCase();
    }

    final nom =
        administration.nom.trim();

    return nom.isEmpty
        ? '?'
        : nom[0].toUpperCase();
  }
}

class _DetailAdministration
    extends StatelessWidget {
  const _DetailAdministration({
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
          size: 19,
          color: Theme.of(context)
              .colorScheme
              .primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$label : ${valeur.trim()}',
          ),
        ),
      ],
    );
  }
}

class _AdministrationFormDialog
    extends StatefulWidget {
  const _AdministrationFormDialog({
    this.administration,
  });

  final AdministrationMarche? administration;

  bool get estModification =>
      administration != null;

  @override
  State<_AdministrationFormDialog>
      createState() =>
          _AdministrationFormDialogState();
}

class _AdministrationFormDialogState
    extends State<_AdministrationFormDialog> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  late final TextEditingController
      _nomController;

  late final TextEditingController
      _sigleController;

  late final TextEditingController
      _typeEntiteController;

  late final TextEditingController
      _adresseController;

  late final TextEditingController
      _telephoneController;

  late final TextEditingController
      _emailController;

  @override
  void initState() {
    super.initState();

    final administration =
        widget.administration;

    _nomController = TextEditingController(
      text: administration?.nom ?? '',
    );

    _sigleController = TextEditingController(
      text: administration?.sigle ?? '',
    );

    _typeEntiteController =
        TextEditingController(
      text: administration?.typeEntite ?? '',
    );

    _adresseController =
        TextEditingController(
      text: administration?.adresse ?? '',
    );

    _telephoneController =
        TextEditingController(
      text: administration?.telephone ?? '',
    );

    _emailController = TextEditingController(
      text: administration?.email ?? '',
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _sigleController.dispose();
    _typeEntiteController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _confirmer() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      DonneesAdministration(
        nom: _nomController.text.trim(),
        sigle:
            _sigleController.text.trim(),
        typeEntite:
            _typeEntiteController.text.trim(),
        adresse:
            _adresseController.text.trim(),
        telephone:
            _telephoneController.text.trim(),
        email:
            _emailController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.estModification
            ? 'Modifier l’administration'
            : 'Créer une administration',
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
                    labelText:
                        'Nom de l’administration *',
                    prefixIcon: Icon(
                      Icons
                          .account_balance_outlined,
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
                      _sigleController,
                  textCapitalization:
                      TextCapitalization.characters,
                  decoration:
                      const InputDecoration(
                    labelText: 'Sigle',
                    hintText:
                        'Exemple : ARMP',
                    prefixIcon: Icon(
                      Icons.short_text_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller:
                      _typeEntiteController,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Type d’entité',
                    hintText:
                        'Exemple : Ministère',
                    prefixIcon: Icon(
                      Icons
                          .account_tree_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller:
                      _adresseController,
                  keyboardType:
                      TextInputType.streetAddress,
                  textCapitalization:
                      TextCapitalization.sentences,
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
                    final email =
                        value?.trim() ?? '';

                    if (email.isEmpty) {
                      return null;
                    }

                    final emailValide = RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(email);

                    if (!emailValide) {
                      return 'L’adresse e-mail est invalide.';
                    }

                    return null;
                  },
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
                    .add_business_outlined,
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

class _StatutAdministrationDialog
    extends StatefulWidget {
  const _StatutAdministrationDialog({
    required this.administration,
  });

  final AdministrationMarche administration;

  @override
  State<_StatutAdministrationDialog>
      createState() =>
          _StatutAdministrationDialogState();
}

class _StatutAdministrationDialogState
    extends State<
        _StatutAdministrationDialog> {
  @override
  Widget build(BuildContext context) {
    final estActif =
        widget.administration.actif;

    final nouveauStatut = !estActif;

    return AlertDialog(
      title: Text(
        estActif
            ? 'Désactiver l’administration'
            : 'Activer l’administration',
      ),
      content: Text(
        estActif
            ? 'Voulez-vous vraiment désactiver '
                '« ${widget.administration.nomAffiche} » ? '
                'Ses comptes utilisateurs actifs '
                'doivent être désactivés au préalable.'
            : 'Voulez-vous vraiment activer '
                '« ${widget.administration.nomAffiche} » ?',
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
          onPressed: () {
            Navigator.of(context).pop(
              nouveauStatut,
            );
          },
          icon: Icon(
            estActif
                ? Icons.block_outlined
                : Icons
                    .check_circle_outline,
          ),
          label: Text(
            estActif ? 'Désactiver' : 'Activer',
          ),
        ),
      ],
    );
  }
}

class _ErreurAdministrations
    extends StatelessWidget {
  const _ErreurAdministrations({
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
          mainAxisSize:
              MainAxisSize.min,
          children: [
            CircleIcon.erreur(context),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign:
                  TextAlign.center,
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

class _AdministrationsVides
    extends StatelessWidget {
  const _AdministrationsVides({
    required this.filtreActif,
    required this.onActualiser,
  });

  final bool filtreActif;
  final Future<void> Function()
      onActualiser;

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
            icon: filtreActif
                ? Icons.search_off_outlined
                : Icons.account_balance_outlined,
          ),
          const SizedBox(height: 20),
          Text(
            filtreActif
                ? 'Aucune administration ne correspond à la recherche.'
                : 'Aucune administration disponible.',
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