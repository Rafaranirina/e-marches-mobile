import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/appel_offre.dart';
import '../data/appel_offre_referentiels.dart';
import '../data/appel_offre_repository.dart';
import 'appel_offre_form_controller.dart';

class AppelOffreFormPage extends StatelessWidget {
  const AppelOffreFormPage({
    this.appelOffre,
    super.key,
  });

  final AppelOffre? appelOffre;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          AppelOffreFormController()..chargerReferentiels(),
      child: _AppelOffreFormView(
        appelOffre: appelOffre,
      ),
    );
  }
}

class _AppelOffreFormView extends StatefulWidget {
  const _AppelOffreFormView({
    required this.appelOffre,
  });

  final AppelOffre? appelOffre;

  @override
  State<_AppelOffreFormView> createState() =>
      _AppelOffreFormViewState();
}

class _AppelOffreFormViewState
    extends State<_AppelOffreFormView> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  late final TextEditingController _referenceController;
  late final TextEditingController _titreController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _montantController;

  String? _typeMarche;
  String? _administrationId;
  String? _categorieId;

  DateTime? _dateLimiteSoumission;
  DateTime? _dateOuverturePlis;

  bool get _isModification => widget.appelOffre != null;

  @override
  void initState() {
    super.initState();

    final appelOffre = widget.appelOffre;

    _referenceController = TextEditingController(
      text: appelOffre?.reference ?? '',
    );

    _titreController = TextEditingController(
      text: appelOffre?.titre ?? '',
    );

    _descriptionController = TextEditingController(
      text: appelOffre?.description ?? '',
    );

    _montantController = TextEditingController(
      text: _formatMontantInitial(
        appelOffre?.montantEstime,
      ),
    );

    _typeMarche = _valeurOuNull(
      appelOffre?.typeMarche,
    );

    _administrationId = _valeurOuNull(
      appelOffre?.administrationId,
    );

    _categorieId = _valeurOuNull(
      appelOffre?.categorieId,
    );

    _dateLimiteSoumission =
        appelOffre?.dateLimiteSoumission?.toLocal();

    _dateOuverturePlis =
        appelOffre?.dateOuverturePlis?.toLocal();
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _titreController.dispose();
    _descriptionController.dispose();
    _montantController.dispose();

    super.dispose();
  }

  Future<void> _enregistrer() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final administrationId = _administrationId;

    if (administrationId == null ||
        administrationId.isEmpty) {
      _afficherMessage(
        'Sélectionnez une administration.',
      );
      return;
    }

    final montant = _parseMontant(
      _montantController.text,
    );

    final controller =
        context.read<AppelOffreFormController>();

    final resultat = await controller.enregistrer(
      appelOffreExistant: widget.appelOffre,
      reference: _referenceController.text,
      titre: _titreController.text,
      description: _descriptionController.text,
      typeMarche: _typeMarche ?? '',
      administrationId: administrationId,
      categorieId: _categorieId,
      montantEstime: montant,
      dateLimiteSoumission: _dateLimiteSoumission,
      dateOuverturePlis: _dateOuverturePlis,
    );

    if (!mounted) {
      return;
    }

    if (resultat == null) {
      _afficherMessage(
        controller.errorMessage ??
            'Impossible d’enregistrer l’appel d’offres.',
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultat.message),
      ),
    );

    Navigator.of(context).pop<AppelOffreActionResult>(
      resultat,
    );
  }

  Future<void> _selectionnerDateLimite() async {
    final resultat = await _selectionnerDateHeure(
      valeurInitiale: _dateLimiteSoumission,
      titre: 'Date limite de soumission',
    );

    if (resultat == null || !mounted) {
      return;
    }

    setState(() {
      _dateLimiteSoumission = resultat;
    });
  }

  Future<void> _selectionnerDateOuverture() async {
    final resultat = await _selectionnerDateHeure(
      valeurInitiale: _dateOuverturePlis,
      titre: 'Date d’ouverture des plis',
    );

    if (resultat == null || !mounted) {
      return;
    }

    setState(() {
      _dateOuverturePlis = resultat;
    });
  }

  Future<DateTime?> _selectionnerDateHeure({
    required DateTime? valeurInitiale,
    required String titre,
  }) async {
    final maintenant = DateTime.now();
    final dateInitiale = valeurInitiale ?? maintenant;

    final date = await showDatePicker(
      context: context,
      helpText: titre,
      initialDate: dateInitiale,
      firstDate: DateTime(
        maintenant.year - 1,
      ),
      lastDate: DateTime(
        maintenant.year + 10,
      ),
    );

    if (date == null || !mounted) {
      return null;
    }

    final heure = await showTimePicker(
      context: context,
      helpText: titre,
      initialTime: TimeOfDay.fromDateTime(
        dateInitiale,
      ),
    );

    if (heure == null) {
      return DateTime(
        date.year,
        date.month,
        date.day,
      );
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      heure.hour,
      heure.minute,
    );
  }

  void _afficherMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        context.watch<AppelOffreFormController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isModification
              ? 'Modifier l’appel d’offres'
              : 'Nouvel appel d’offres',
        ),
      ),
      body: SafeArea(
        child: _buildBody(controller),
      ),
    );
  }

  Widget _buildBody(
    AppelOffreFormController controller,
  ) {
    if (controller.isLoadingReferentiels) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.hasError &&
        controller.administrations.isEmpty) {
      return _ErreurReferentiels(
        message: controller.errorMessage ??
            'Impossible de charger le formulaire.',
        onRetry: controller.chargerReferentiels,
      );
    }

    return AbsorbPointer(
      absorbing: controller.isSubmitting,
      child: Form(
        key: _formKey,
        autovalidateMode:
            AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInformationsGenerales(controller),
            const SizedBox(height: 16),
            _buildClassification(controller),
            const SizedBox(height: 16),
            _buildCalendrier(),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: controller.isSubmitting
                  ? null
                  : _enregistrer,
              icon: controller.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                controller.isSubmitting
                    ? 'Enregistrement...'
                    : _isModification
                        ? 'Enregistrer les modifications'
                        : 'Créer le brouillon',
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationsGenerales(
    AppelOffreFormController controller,
  ) {
    return _FormSection(
      titre: 'Informations générales',
      enfants: [
        TextFormField(
          controller: _referenceController,
          textCapitalization:
              TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Référence *',
            hintText: 'Exemple : AO-2026-001',
            prefixIcon:
                Icon(Icons.numbers_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null ||
                value.trim().isEmpty) {
              return 'La référence est obligatoire.';
            }

            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titreController,
          textCapitalization:
              TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Titre *',
            prefixIcon:
                Icon(Icons.title_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null ||
                value.trim().isEmpty) {
              return 'Le titre est obligatoire.';
            }

            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          minLines: 4,
          maxLines: 8,
          textCapitalization:
              TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Description',
            alignLabelWithHint: true,
            prefixIcon:
                Icon(Icons.description_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _montantController,
          keyboardType:
              const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: const InputDecoration(
            labelText: 'Montant estimé',
            suffixText: 'Ar',
            prefixIcon:
                Icon(Icons.payments_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            final texte = value?.trim() ?? '';

            if (texte.isEmpty) {
              return null;
            }

            final montant = _parseMontant(texte);

            if (montant == null) {
              return 'Saisissez un montant valide.';
            }

            if (montant < 0) {
              return 'Le montant ne peut pas être négatif.';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildClassification(
    AppelOffreFormController controller,
  ) {
    final typeInitial =
        AppelOffreFormController.typesMarche.contains(
      _typeMarche,
    )
            ? _typeMarche
            : null;

    final administrationInitiale =
        _contientAdministration(
      controller.administrations,
      _administrationId,
    )
            ? _administrationId
            : null;

    final categorieInitiale = _contientCategorie(
      controller.categories,
      _categorieId,
    )
        ? _categorieId
        : null;

    return _FormSection(
      titre: 'Classification',
      enfants: [
        DropdownButtonFormField<String>(
          initialValue: typeInitial,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Type de marché *',
            prefixIcon:
                Icon(Icons.work_outline),
            border: OutlineInputBorder(),
          ),
          items: AppelOffreFormController.typesMarche
              .map(
                (type) => DropdownMenuItem<String>(
                  value: type,
                  child: Text(
                    _libelleTypeMarche(type),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _typeMarche = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Sélectionnez un type de marché.';
            }

            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: administrationInitiale,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Administration *',
            prefixIcon:
                Icon(Icons.account_balance_outlined),
            border: OutlineInputBorder(),
          ),
          items: controller.administrations
              .map(
                (administration) =>
                    DropdownMenuItem<String>(
                  value: administration.id,
                  child: Text(
                    administration.libelle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _administrationId = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Sélectionnez une administration.';
            }

            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String?>(
          initialValue: categorieInitiale,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Catégorie',
            prefixIcon:
                Icon(Icons.category_outlined),
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Aucune catégorie'),
            ),
            ...controller.categories.map(
              (categorie) =>
                  DropdownMenuItem<String?>(
                value: categorie.id,
                child: Text(
                  categorie.nom,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _categorieId = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCalendrier() {
    return _FormSection(
      titre: 'Calendrier',
      enfants: [
        _DateTimeField(
          label: 'Date limite de soumission',
          valeur: _dateLimiteSoumission,
          icon: Icons.event_busy_outlined,
          onTap: _selectionnerDateLimite,
          onClear: _dateLimiteSoumission == null
              ? null
              : () {
                  setState(() {
                    _dateLimiteSoumission = null;
                  });
                },
        ),
        const SizedBox(height: 16),
        _DateTimeField(
          label: 'Date d’ouverture des plis',
          valeur: _dateOuverturePlis,
          icon: Icons.event_available_outlined,
          onTap: _selectionnerDateOuverture,
          onClear: _dateOuverturePlis == null
              ? null
              : () {
                  setState(() {
                    _dateOuverturePlis = null;
                  });
                },
        ),
        if (_datesInvalides) ...[
          const SizedBox(height: 12),
          Text(
            'La date d’ouverture des plis doit être postérieure ou égale à la date limite.',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .error,
            ),
          ),
        ],
      ],
    );
  }

  bool get _datesInvalides {
    final dateLimite = _dateLimiteSoumission;
    final dateOuverture = _dateOuverturePlis;

    if (dateLimite == null || dateOuverture == null) {
      return false;
    }

    return dateOuverture.isBefore(dateLimite);
  }

  static String? _valeurOuNull(String? valeur) {
    final texte = valeur?.trim() ?? '';

    return texte.isEmpty ? null : texte;
  }

  static String _formatMontantInitial(
    double? montant,
  ) {
    if (montant == null) {
      return '';
    }

    if (montant == montant.roundToDouble()) {
      return montant.toInt().toString();
    }

    return montant.toString();
  }

  static double? _parseMontant(String valeur) {
    final texte = valeur
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(',', '.')
        .trim();

    if (texte.isEmpty) {
      return null;
    }

    return double.tryParse(texte);
  }

  static bool _contientAdministration(
    List<AdministrationOption> administrations,
    String? id,
  ) {
    if (id == null) {
      return false;
    }

    return administrations.any(
      (administration) => administration.id == id,
    );
  }

  static bool _contientCategorie(
    List<CategorieOption> categories,
    String? id,
  ) {
    if (id == null) {
      return false;
    }

    return categories.any(
      (categorie) => categorie.id == id,
    );
  }

  static String _libelleTypeMarche(String type) {
    switch (type) {
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

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.titre,
    required this.enfants,
  });

  final String titre;
  final List<Widget> enfants;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              titre,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(height: 28),
            ...enfants,
          ],
        ),
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.valeur,
    required this.icon,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final DateTime? valeur;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: onClear == null
              ? const Icon(Icons.calendar_month_outlined)
              : IconButton(
                  tooltip: 'Effacer',
                  onPressed: onClear,
                  icon: const Icon(Icons.clear),
                ),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          valeur == null
              ? 'Non renseignée'
              : _formatDateTime(valeur!),
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime date) {
    final jour = date.day.toString().padLeft(2, '0');
    final mois = date.month.toString().padLeft(2, '0');
    final heure = date.hour.toString().padLeft(2, '0');
    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$jour/$mois/${date.year} à $heure:$minute';
  }
}

class _ErreurReferentiels extends StatelessWidget {
  const _ErreurReferentiels({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
