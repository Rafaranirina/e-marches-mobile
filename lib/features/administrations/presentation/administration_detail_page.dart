import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/actif_statut_styles.dart';
import '../../../shared/widgets/circle_icon.dart';
import '../../../shared/widgets/statut_chip.dart';
import '../data/administration_marche.dart';
import 'administration_controller.dart';

class AdministrationDetailPage
    extends StatefulWidget {
  const AdministrationDetailPage({
    super.key,
    required this.administrationId,
  });

  final String administrationId;

  @override
  State<AdministrationDetailPage>
      createState() =>
          _AdministrationDetailPageState();
}

class _AdministrationDetailPageState
    extends State<AdministrationDetailPage> {
  bool _chargementInitial = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      _chargerDetail();
    });
  }

  Future<void> _chargerDetail() async {
    final controller = context
        .read<AdministrationController>();

    await controller.obtenirDetail(
      widget.administrationId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _chargementInitial = false;
    });
  }

  Future<void> _modifier(
    AdministrationMarche administration,
  ) async {
    final donnees =
        await showDialog<DonneesAdministration>(
      context: context,
      builder: (_) => _FormDialogDetail(
        administration: administration,
      ),
    );

    if (donnees == null || !mounted) {
      return;
    }

    final controller = context
        .read<AdministrationController>();

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
    final estActif = administration.actif;

    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          estActif
              ? 'Désactiver l’administration'
              : 'Activer l’administration',
        ),
        content: Text(
          estActif
              ? 'Voulez-vous vraiment désactiver '
                  '« ${administration.nomAffiche} » ? '
                  'Ses comptes utilisateurs actifs '
                  'doivent être désactivés au préalable.'
              : 'Voulez-vous vraiment activer '
                  '« ${administration.nomAffiche} » ?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(
                false,
              );
            },
            child: const Text(
              'Annuler',
            ),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop(
                true,
              );
            },
            icon: Icon(
              estActif
                  ? Icons.block_outlined
                  : Icons
                      .check_circle_outline,
            ),
            label: Text(
              estActif
                  ? 'Désactiver'
                  : 'Activer',
            ),
          ),
        ],
      ),
    );

    if (confirme != true || !mounted) {
      return;
    }

    final controller = context
        .read<AdministrationController>();

    final resultat =
        await controller.changerStatut(
      administration: administration,
      actif: !estActif,
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

    final administration =
        controller.trouverParId(
      widget.administrationId,
    );

    final actionEnCours =
        controller.actionEnCoursPour(
      widget.administrationId,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          administration?.nomAffiche ??
              'Administration',
        ),
        actions: [
          if (administration != null &&
              !actionEnCours) ...[
            IconButton(
              tooltip: 'Modifier',
              onPressed: () {
                _modifier(administration);
              },
              icon: const Icon(
                Icons.edit_outlined,
              ),
            ),
            IconButton(
              tooltip: administration.actif
                  ? 'Désactiver'
                  : 'Activer',
              onPressed: () {
                _changerStatut(
                  administration,
                );
              },
              icon: Icon(
                administration.actif
                    ? Icons.block_outlined
                    : Icons
                        .check_circle_outline,
              ),
            ),
          ],
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
        child: _buildContenu(
          controller,
          administration,
        ),
      ),
    );
  }

  Widget _buildContenu(
    AdministrationController controller,
    AdministrationMarche? administration,
  ) {
    if (_chargementInitial &&
        administration == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (administration == null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleIcon.erreur(context),
              const SizedBox(height: 20),
              Text(
                controller.errorMessage ??
                    'Administration introuvable.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _chargerDetail,
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

    return RefreshIndicator(
      onRefresh: _chargerDetail,
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
                        child: Icon(
                          Icons
                              .account_balance_outlined,
                        ),
                      ),
                      const SizedBox(
                        width: 14,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              administration
                                  .nom,
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
                            if (administration
                                .sigle
                                .trim()
                                .isNotEmpty) ...[
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                administration
                                    .sigle,
                              ),
                            ],
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
                      if (administration
                          .typeEntite
                          .trim()
                          .isNotEmpty)
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
                        statut: cleActifStatut(
                          administration.actif,
                        ),
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
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistiques',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTuile(
                          icon: Icons
                              .people_alt_outlined,
                          label:
                              'Utilisateurs',
                          valeur: administration
                              .nombreUtilisateurs,
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: _StatTuile(
                          icon: Icons
                              .campaign_outlined,
                          label:
                              'Appels d’offres',
                          valeur: administration
                              .nombreAppelsOffres,
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: _StatTuile(
                          icon: Icons
                              .assignment_outlined,
                          label: 'Contrats',
                          valeur: administration
                              .nombreContrats,
                        ),
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
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coordonnées',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 14),
                  _LigneDetail(
                    icon: Icons
                        .location_on_outlined,
                    label: 'Adresse',
                    valeur:
                        administration.adresse,
                  ),
                  const SizedBox(height: 10),
                  _LigneDetail(
                    icon:
                        Icons.phone_outlined,
                    label: 'Téléphone',
                    valeur: administration
                        .telephone,
                  ),
                  const SizedBox(height: 10),
                  _LigneDetail(
                    icon:
                        Icons.email_outlined,
                    label: 'E-mail',
                    valeur:
                        administration.email,
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
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dates',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 14),
                  _LigneDetail(
                    icon:
                        Icons.event_outlined,
                    label: 'Créée le',
                    valeur: _formatDateHeure(
                      administration
                          .dateCreation,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _LigneDetail(
                    icon: Icons
                        .update_outlined,
                    label: 'Mise à jour le',
                    valeur: _formatDateHeure(
                      administration.dateMaj,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTuile extends StatelessWidget {
  const _StatTuile({
    required this.icon,
    required this.label,
    required this.valeur,
  });

  final IconData icon;
  final String label;
  final int valeur;

  @override
  Widget build(BuildContext context) {
    final couleurs =
        Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: couleurs.surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: couleurs.primary,
          ),
          const SizedBox(height: 8),
          Text(
            '$valeur',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall,
          ),
        ],
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

class _FormDialogDetail
    extends StatefulWidget {
  const _FormDialogDetail({
    required this.administration,
  });

  final AdministrationMarche administration;

  @override
  State<_FormDialogDetail> createState() =>
      _FormDialogDetailState();
}

class _FormDialogDetailState
    extends State<_FormDialogDetail> {
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

    final administration = widget.administration;

    _nomController = TextEditingController(
      text: administration.nom,
    );

    _sigleController = TextEditingController(
      text: administration.sigle,
    );

    _typeEntiteController =
        TextEditingController(
      text: administration.typeEntite,
    );

    _adresseController = TextEditingController(
      text: administration.adresse,
    );

    _telephoneController =
        TextEditingController(
      text: administration.telephone,
    );

    _emailController = TextEditingController(
      text: administration.email,
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
        sigle: _sigleController.text.trim(),
        typeEntite:
            _typeEntiteController.text.trim(),
        adresse:
            _adresseController.text.trim(),
        telephone:
            _telephoneController.text.trim(),
        email: _emailController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Modifier l’administration',
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
              mainAxisSize: MainAxisSize.min,
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
                  controller: _sigleController,
                  textCapitalization:
                      TextCapitalization
                          .characters,
                  decoration:
                      const InputDecoration(
                    labelText: 'Sigle',
                    hintText: 'Exemple : ARMP',
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
                    labelText: 'Type d’entité',
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
                  keyboardType: TextInputType
                      .streetAddress,
                  textCapitalization:
                      TextCapitalization
                          .sentences,
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
                  controller: _emailController,
                  keyboardType: TextInputType
                      .emailAddress,
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
          icon: const Icon(
            Icons.save_outlined,
          ),
          label: const Text(
            'Enregistrer',
          ),
        ),
      ],
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
