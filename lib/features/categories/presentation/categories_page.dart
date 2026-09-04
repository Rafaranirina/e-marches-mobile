import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/actif_statut_styles.dart';
import '../../../shared/widgets/circle_icon.dart';
import '../../../shared/widgets/statut_chip.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/categorie_marche.dart';
import 'categorie_controller.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final estAdministrateurNational =
        context
                .read<AuthController>()
                .utilisateur
                ?.role
                .trim()
                .toLowerCase() ==
            'admin_national';

    return ChangeNotifierProvider(
      create: (_) => CategorieController()
        ..charger(
          modeGestion:
              estAdministrateurNational,
        ),
      child: const _CategoriesView(),
    );
  }
}

class _CategoriesView extends StatefulWidget {
  const _CategoriesView();

  @override
  State<_CategoriesView> createState() =>
      _CategoriesViewState();
}

class _CategoriesViewState
    extends State<_CategoriesView> {
  final TextEditingController
      _rechercheController =
      TextEditingController();

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  Future<void> _creerCategorie() async {
    final controller =
        context.read<CategorieController>();

    final donnees =
        await showDialog<DonneesCategorie>(
      context: context,
      builder: (_) => _CategorieFormDialog(
        categoriesDisponibles:
            controller.categories,
      ),
    );

    if (donnees == null || !mounted) {
      return;
    }

    final resultat =
        await controller.creerCategorie(
      donnees,
    );

    if (!mounted) {
      return;
    }

    _afficherMessage(
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de créer la catégorie.',
      estErreur: resultat == null,
    );
  }

  Future<void> _modifierCategorie(
    CategorieMarche categorie,
  ) async {
    final controller =
        context.read<CategorieController>();

    final donnees =
        await showDialog<DonneesCategorie>(
      context: context,
      builder: (_) => _CategorieFormDialog(
        categoriesDisponibles:
            controller.categories,
        categorie: categorie,
      ),
    );

    if (donnees == null || !mounted) {
      return;
    }

    final resultat =
        await controller.modifierCategorie(
      categorie: categorie,
      donnees: donnees,
    );

    if (!mounted) {
      return;
    }

    _afficherMessage(
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de modifier la catégorie.',
      estErreur: resultat == null,
    );
  }

  Future<void> _changerStatut(
    CategorieMarche categorie,
  ) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => _StatutCategorieDialog(
        categorie: categorie,
      ),
    );

    if (confirme != true || !mounted) {
      return;
    }

    final controller =
        context.read<CategorieController>();

    final resultat =
        await controller.changerStatut(
      categorie: categorie,
      actif: !categorie.actif,
    );

    if (!mounted) {
      return;
    }

    _afficherMessage(
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de modifier le statut de la catégorie.',
      estErreur: resultat == null,
    );
  }

  Future<void> _ouvrirDetail(
    CategorieMarche categorie,
  ) async {
    final controller =
        context.read<CategorieController>();

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            ChangeNotifierProvider.value(
          value: controller,
          child: _CategorieDetailPage(
            categorieId: categorie.id,
          ),
        ),
      ),
    );
  }

  void _reinitialiserFiltres() {
    _rechercheController.clear();

    context
        .read<CategorieController>()
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
        context.watch<CategorieController>();

    final utilisateur = context
        .watch<AuthController>()
        .utilisateur;

    final estAdministrateurNational =
        utilisateur?.role
                .trim()
                .toLowerCase() ==
            'admin_national';

    final categories =
        controller.categoriesFiltrees;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Catégories',
        ),
        actions: [
          if (estAdministrateurNational)
            IconButton(
              tooltip:
                  'Créer une catégorie',
              onPressed: controller.isBusy
                  ? null
                  : _creerCategorie,
              icon: const Icon(
                Icons.create_new_folder_outlined,
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
                          : _creerCategorie,
                  icon: const Icon(
                    Icons
                        .create_new_folder_outlined,
                  ),
                  label: const Text(
                    'Nouvelle catégorie',
                  ),
                )
              : null,
      body: SafeArea(
        child: Column(
          children: [
            _EnteteCategories(
              nombreTotal:
                  controller.nombreTotal,
              nombrePrincipales:
                  controller
                      .nombrePrincipales,
              nombreSousCategories:
                  controller
                      .nombreSousCategories,
              nombreInactives:
                  controller
                      .nombreInactives,
              afficherInactives:
                  estAdministrateurNational,
            ),
            _FiltresCategories(
              rechercheController:
                  _rechercheController,
              typeSelectionne:
                  controller.filtreType,
              statutSelectionne:
                  controller.filtreStatut,
              afficherFiltreStatut:
                  estAdministrateurNational,
              onRecherche:
                  controller.rechercher,
              onType:
                  controller.filtrerParType,
              onStatut: controller
                  .filtrerParStatut,
              onReinitialiser:
                  _reinitialiserFiltres,
            ),
            Expanded(
              child: _buildContenu(
                controller,
                categories,
                estAdministrateurNational:
                    estAdministrateurNational,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenu(
    CategorieController controller,
    List<CategorieMarche> categories, {
    required bool estAdministrateurNational,
  }) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.hasError &&
        controller.categories.isEmpty) {
      return _ErreurCategories(
        message: controller.errorMessage ??
            'Impossible de charger les catégories.',
        onRetry: () => controller.charger(
          modeGestion:
              estAdministrateurNational,
        ),
      );
    }

    if (controller.categories.isEmpty) {
      return _CategoriesVides(
        filtreActif: false,
        onActualiser:
            controller.actualiser,
      );
    }

    if (categories.isEmpty) {
      return _CategoriesVides(
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
        itemCount: categories.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final categorie =
              categories[index];

          return _CategorieCard(
            categorie: categorie,
            nomCategorieParente:
                controller
                    .nomCategorieParId(
              categorie.categorieParentId,
            ),
            estAdministrateurNational:
                estAdministrateurNational,
            actionEnCours:
                controller.actionEnCoursPour(
              categorie.id,
            ),
            onTap: estAdministrateurNational
                ? () {
                    _ouvrirDetail(
                      categorie,
                    );
                  }
                : null,
            onModifier: () {
              _modifierCategorie(
                categorie,
              );
            },
            onChangerStatut: () {
              _changerStatut(
                categorie,
              );
            },
          );
        },
      ),
    );
  }
}

class _EnteteCategories
    extends StatelessWidget {
  const _EnteteCategories({
    required this.nombreTotal,
    required this.nombrePrincipales,
    required this.nombreSousCategories,
    required this.nombreInactives,
    required this.afficherInactives,
  });

  final int nombreTotal;
  final int nombrePrincipales;
  final int nombreSousCategories;
  final int nombreInactives;
  final bool afficherInactives;

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
                      Icons.category_outlined,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '$nombreTotal catégorie'
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
                        Icons.folder_outlined,
                    label: 'Principales',
                    valeur:
                        nombrePrincipales,
                  ),
                  _CompteurChip(
                    icon:
                        Icons.subdirectory_arrow_right_outlined,
                    label:
                        'Sous-catégories',
                    valeur:
                        nombreSousCategories,
                  ),
                  if (afficherInactives)
                    _CompteurChip(
                      icon: Icons
                          .visibility_off_outlined,
                      label: 'Inactives',
                      valeur:
                          nombreInactives,
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

class _FiltresCategories
    extends StatelessWidget {
  const _FiltresCategories({
    required this.rechercheController,
    required this.typeSelectionne,
    required this.statutSelectionne,
    required this.afficherFiltreStatut,
    required this.onRecherche,
    required this.onType,
    required this.onStatut,
    required this.onReinitialiser,
  });

  final TextEditingController
      rechercheController;

  final String typeSelectionne;
  final String statutSelectionne;
  final bool afficherFiltreStatut;

  final ValueChanged<String> onRecherche;
  final ValueChanged<String> onType;
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
                      'Rechercher une catégorie',
                  hintText:
                      'Nom ou description',
                  prefixIcon: Icon(
                    Icons.search_outlined,
                  ),
                  border:
                      OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue:
                    typeSelectionne,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Type de catégorie',
                  prefixIcon: Icon(
                    Icons.filter_list_outlined,
                  ),
                  border:
                      OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'toutes',
                    child: Text(
                      'Toutes les catégories',
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'principales',
                    child: Text(
                      'Catégories principales',
                    ),
                  ),
                  DropdownMenuItem(
                    value:
                        'sous_categories',
                    child: Text(
                      'Sous-catégories',
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onType(value);
                  }
                },
              ),
              if (afficherFiltreStatut) ...[
                const SizedBox(height: 12),
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
                      value: 'toutes',
                      child: Text(
                        'Tous les statuts',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'actives',
                      child: Text(
                        'Actives',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'inactives',
                      child: Text(
                        'Inactives',
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onStatut(value);
                    }
                  },
                ),
              ],
              const SizedBox(height: 10),
              Align(
                alignment:
                    Alignment.centerRight,
                child: TextButton.icon(
                  onPressed:
                      onReinitialiser,
                  icon: const Icon(
                    Icons
                        .filter_alt_off_outlined,
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

enum _ActionCategorie {
  modifier,
  statut,
}

class _CategorieCard extends StatelessWidget {
  const _CategorieCard({
    required this.categorie,
    required this.nomCategorieParente,
    required this.estAdministrateurNational,
    required this.actionEnCours,
    required this.onModifier,
    required this.onChangerStatut,
    this.onTap,
  });

  final CategorieMarche categorie;
  final String nomCategorieParente;
  final bool estAdministrateurNational;
  final bool actionEnCours;

  final VoidCallback onModifier;
  final VoidCallback onChangerStatut;
  final VoidCallback? onTap;

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
                    child: Icon(
                      categorie
                              .estCategoriePrincipale
                          ? Icons
                              .folder_outlined
                          : Icons
                              .subdirectory_arrow_right_outlined,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          categorie.nom,
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
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          categorie
                              .descriptionAffichee,
                        ),
                      ],
                    ),
                  ),
                  if (estAdministrateurNational)
                    if (actionEnCours)
                      const Padding(
                        padding:
                            EdgeInsets.all(
                          10,
                        ),
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
                          _ActionCategorie>(
                        tooltip: 'Actions',
                        onSelected: (action) {
                          switch (action) {
                            case _ActionCategorie
                                  .modifier:
                              onModifier();
                              break;

                            case _ActionCategorie
                                  .statut:
                              onChangerStatut();
                              break;
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value:
                                _ActionCategorie
                                    .modifier,
                            child: ListTile(
                              contentPadding:
                                  EdgeInsets
                                      .zero,
                              leading: Icon(
                                Icons
                                    .edit_outlined,
                              ),
                              title: Text(
                                'Modifier',
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value:
                                _ActionCategorie
                                    .statut,
                            child: ListTile(
                              contentPadding:
                                  EdgeInsets
                                      .zero,
                              leading: Icon(
                                categorie.actif
                                    ? Icons
                                        .visibility_off_outlined
                                    : Icons
                                        .visibility_outlined,
                              ),
                              title: Text(
                                categorie.actif
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
                  Chip(
                    avatar: Icon(
                      categorie
                              .estCategoriePrincipale
                          ? Icons
                              .account_tree_outlined
                          : Icons
                              .subdirectory_arrow_right_outlined,
                      size: 17,
                    ),
                    label: Text(
                      categorie
                              .estCategoriePrincipale
                          ? 'Catégorie principale'
                          : 'Sous-catégorie',
                    ),
                  ),
                  if (estAdministrateurNational)
                    StatutChip(
                      statut: cleActifStatut(categorie.actif),
                      styles: actifStatutStyles,
                    ),
                ],
              ),
              if (categorie
                  .estSousCategorie) ...[
                const Divider(height: 28),
                _DetailCategorie(
                  icon: Icons
                      .folder_copy_outlined,
                  label:
                      'Catégorie parente',
                  valeur:
                      nomCategorieParente,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailCategorie
    extends StatelessWidget {
  const _DetailCategorie({
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
            '$label : $valeur',
          ),
        ),
      ],
    );
  }
}

class _CategorieFormDialog
    extends StatefulWidget {
  const _CategorieFormDialog({
    required this.categoriesDisponibles,
    this.categorie,
  });

  final List<CategorieMarche>
      categoriesDisponibles;

  final CategorieMarche? categorie;

  bool get estModification =>
      categorie != null;

  @override
  State<_CategorieFormDialog>
      createState() =>
          _CategorieFormDialogState();
}

class _CategorieFormDialogState
    extends State<_CategorieFormDialog> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  late final TextEditingController
      _nomController;

  late final TextEditingController
      _descriptionController;

  String? _categorieParentId;

  @override
  void initState() {
    super.initState();

    final categorie = widget.categorie;

    _nomController = TextEditingController(
      text: categorie?.nom ?? '',
    );

    _descriptionController =
        TextEditingController(
      text: categorie?.description ?? '',
    );

    _categorieParentId =
        categorie?.categorieParentId;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _confirmer() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      DonneesCategorie(
        nom: _nomController.text.trim(),
        description:
            _descriptionController
                .text
                .trim(),
        categorieParentId:
            _categorieParentId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categorieActuelleId =
        widget.categorie?.id;

    final optionsParent =
        List<CategorieMarche>.from(
      widget.categoriesDisponibles,
    )
          ..removeWhere(
            (categorie) =>
                categorie.id ==
                categorieActuelleId,
          )
          ..sort(
            (a, b) => a.nom
                .toLowerCase()
                .compareTo(
                  b.nom.toLowerCase(),
                ),
          );

    final parentValide = optionsParent.any(
          (categorie) =>
              categorie.id ==
              _categorieParentId,
        )
        ? _categorieParentId
        : null;

    return AlertDialog(
      title: Text(
        widget.estModification
            ? 'Modifier la catégorie'
            : 'Créer une catégorie',
      ),
      content: SizedBox(
        width: 540,
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
                      _nomController,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Nom de la catégorie *',
                    prefixIcon: Icon(
                      Icons.category_outlined,
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
                      _descriptionController,
                  textCapitalization:
                      TextCapitalization.sentences,
                  maxLines: 4,
                  decoration:
                      const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(
                      Icons
                          .description_outlined,
                    ),
                    alignLabelWithHint: true,
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue:
                      parentValide ?? '',
                  isExpanded: true,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Catégorie parente',
                    helperText:
                        'Laissez vide pour créer une catégorie principale.',
                    prefixIcon: Icon(
                      Icons
                          .account_tree_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text(
                        'Aucune — catégorie principale',
                      ),
                    ),
                    ...optionsParent.map(
                      (categorie) =>
                          DropdownMenuItem(
                        value: categorie.id,
                        child: Text(
                          categorie.nom,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      final id =
                          value?.trim() ?? '';

                      _categorieParentId =
                          id.isEmpty
                              ? null
                              : id;
                    });
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
                    .create_new_folder_outlined,
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

class _StatutCategorieDialog
    extends StatelessWidget {
  const _StatutCategorieDialog({
    required this.categorie,
  });

  final CategorieMarche categorie;

  @override
  Widget build(BuildContext context) {
    final activer = !categorie.actif;

    return AlertDialog(
      title: Text(
        activer
            ? 'Activer la catégorie'
            : 'Désactiver la catégorie',
      ),
      content: Text(
        activer
            ? 'Voulez-vous activer « ${categorie.nom} » ? '
                'Elle redeviendra visible et sélectionnable.'
            : 'Voulez-vous désactiver « ${categorie.nom} » ? '
                'Elle ne sera plus visible ni sélectionnable. '
                'Ses éventuelles sous-catégories actives doivent '
                'd’abord être désactivées.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text(
            'Annuler',
          ),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          icon: Icon(
            activer
                ? Icons.visibility_outlined
                : Icons
                    .visibility_off_outlined,
          ),
          label: Text(
            activer ? 'Activer' : 'Désactiver',
          ),
        ),
      ],
    );
  }
}

class _CategorieDetailPage
    extends StatefulWidget {
  const _CategorieDetailPage({
    required this.categorieId,
  });

  final String categorieId;

  @override
  State<_CategorieDetailPage>
      createState() =>
          _CategorieDetailPageState();
}

class _CategorieDetailPageState
    extends State<_CategorieDetailPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context
          .read<CategorieController>()
          .rafraichirDetail(
        widget.categorieId,
      );
    });
  }

  Future<void> _modifier(
    CategorieMarche categorie,
  ) async {
    final controller =
        context.read<CategorieController>();

    final donnees =
        await showDialog<DonneesCategorie>(
      context: context,
      builder: (_) => _CategorieFormDialog(
        categoriesDisponibles:
            controller.categories,
        categorie: categorie,
      ),
    );

    if (donnees == null || !mounted) {
      return;
    }

    final resultat =
        await controller.modifierCategorie(
      categorie: categorie,
      donnees: donnees,
    );

    if (!mounted) {
      return;
    }

    _afficherMessage(
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de modifier la catégorie.',
      estErreur: resultat == null,
    );
  }

  Future<void> _changerStatut(
    CategorieMarche categorie,
  ) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => _StatutCategorieDialog(
        categorie: categorie,
      ),
    );

    if (confirme != true || !mounted) {
      return;
    }

    final controller =
        context.read<CategorieController>();

    final resultat =
        await controller.changerStatut(
      categorie: categorie,
      actif: !categorie.actif,
    );

    if (!mounted) {
      return;
    }

    _afficherMessage(
      resultat?.message ??
          controller.errorMessage ??
          'Impossible de modifier le statut de la catégorie.',
      estErreur: resultat == null,
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
    final controller =
        context.watch<CategorieController>();

    final categorie = controller.trouverParId(
      widget.categorieId,
    );

    if (categorie == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Catégorie',
          ),
        ),
        body: const Center(
          child: Text(
            'Cette catégorie est introuvable.',
          ),
        ),
      );
    }

    final actionEnCours =
        controller.actionEnCoursPour(
      categorie.id,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(categorie.nom),
        actions: [
          IconButton(
            tooltip: 'Modifier',
            onPressed: actionEnCours
                ? null
                : () {
                    _modifier(categorie);
                  },
            icon: const Icon(
              Icons.edit_outlined,
            ),
          ),
          IconButton(
            tooltip: categorie.actif
                ? 'Désactiver'
                : 'Activer',
            onPressed: actionEnCours
                ? null
                : () {
                    _changerStatut(
                      categorie,
                    );
                  },
            icon: Icon(
              categorie.actif
                  ? Icons
                      .visibility_off_outlined
                  : Icons
                      .visibility_outlined,
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          child: Icon(
                            categorie
                                    .estCategoriePrincipale
                                ? Icons
                                    .folder_outlined
                                : Icons
                                    .subdirectory_arrow_right_outlined,
                          ),
                        ),
                        const SizedBox(
                          width: 14,
                        ),
                        Expanded(
                          child: Text(
                            categorie.nom,
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
                    const SizedBox(
                      height: 16,
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: Icon(
                            categorie
                                    .estCategoriePrincipale
                                ? Icons
                                    .account_tree_outlined
                                : Icons
                                    .subdirectory_arrow_right_outlined,
                            size: 17,
                          ),
                          label: Text(
                            categorie
                                    .estCategoriePrincipale
                                ? 'Catégorie principale'
                                : 'Sous-catégorie',
                          ),
                        ),
                        StatutChip(
                          statut:
                              cleActifStatut(categorie.actif),
                          styles: actifStatutStyles,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'Informations',
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
                    const SizedBox(
                      height: 14,
                    ),
                    _DetailCategorie(
                      icon: Icons
                          .description_outlined,
                      label: 'Description',
                      valeur: categorie
                          .descriptionAffichee,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    _DetailCategorie(
                      icon: Icons
                          .folder_copy_outlined,
                      label:
                          'Catégorie parente',
                      valeur: categorie
                          .categorieParenteAffichee,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    _DetailCategorie(
                      icon: Icons
                          .subdirectory_arrow_right_outlined,
                      label:
                          'Sous-catégories',
                      valeur:
                          '${categorie.nombreSousCategories}',
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    _DetailCategorie(
                      icon: Icons
                          .campaign_outlined,
                      label:
                          'Appels d’offres liés',
                      valeur:
                          '${categorie.nombreAppelsOffres}',
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    _DetailCategorie(
                      icon:
                          Icons.event_outlined,
                      label: 'Créée le',
                      valeur: _formatDateHeure(
                        categorie
                            .dateCreation,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    _DetailCategorie(
                      icon: Icons
                          .update_outlined,
                      label:
                          'Dernière modification',
                      valeur: _formatDateHeure(
                        categorie.dateMaj,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErreurCategories
    extends StatelessWidget {
  const _ErreurCategories({
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

class _CategoriesVides
    extends StatelessWidget {
  const _CategoriesVides({
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
                : Icons.category_outlined,
          ),
          const SizedBox(height: 20),
          Text(
            filtreActif
                ? 'Aucune catégorie ne correspond aux filtres.'
                : 'Aucune catégorie disponible.',
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
