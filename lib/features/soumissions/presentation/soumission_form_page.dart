import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/soumission_repository.dart';
import 'soumission_form_controller.dart';

class SoumissionFormPage extends StatelessWidget {
  const SoumissionFormPage({
    required this.appelOffreId,
    required this.appelOffreReference,
    super.key,
  });

  final String appelOffreId;
  final String appelOffreReference;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SoumissionFormController(),
      child: _SoumissionFormView(
        appelOffreId: appelOffreId,
        appelOffreReference: appelOffreReference,
      ),
    );
  }
}

class _SoumissionFormView extends StatefulWidget {
  const _SoumissionFormView({
    required this.appelOffreId,
    required this.appelOffreReference,
  });

  final String appelOffreId;
  final String appelOffreReference;

  @override
  State<_SoumissionFormView> createState() =>
      _SoumissionFormViewState();
}

class _SoumissionFormViewState
    extends State<_SoumissionFormView> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _montantController =
      TextEditingController();

  final TextEditingController _delaiController =
      TextEditingController();

  @override
  void dispose() {
    _montantController.dispose();
    _delaiController.dispose();
    super.dispose();
  }

  Future<void> _deposer() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller =
        context.read<SoumissionFormController>();

    final resultat = await controller.deposer(
      appelOffreId: widget.appelOffreId,
      montantPropose: _parseMontant(
        _montantController.text,
      ),
      delaiExecution: _delaiController.text,
    );

    if (!mounted) {
      return;
    }

    if (resultat == null) {
      _afficherMessage(
        controller.errorMessage ??
            'Impossible de déposer la soumission.',
        estErreur: true,
      );
      return;
    }

    _afficherMessage(resultat.message);

    Navigator.of(context).pop<SoumissionActionResult>(
      resultat,
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
              ? Theme.of(context).colorScheme.error
              : null,
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        context.watch<SoumissionFormController>();

    final referenceAppelOffre =
        widget.appelOffreReference.trim().isEmpty
            ? 'Appel d’offres'
            : widget.appelOffreReference;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Déposer une soumission',
        ),
        bottom: controller.isSubmitting
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: controller.isSubmitting,
          child: Form(
            key: _formKey,
            autovalidateMode:
                AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          child: Icon(
                            Icons.description_outlined,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Appel d’offres',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(referenceAppelOffre),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Informations de la soumission',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Divider(height: 28),
                        TextFormField(
                          controller:
                              _montantController,
                          keyboardType:
                              const TextInputType
                                  .numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction:
                              TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText:
                                'Montant proposé *',
                            hintText: 'Exemple : 5000000',
                            suffixText: 'Ar',
                            prefixIcon: Icon(
                              Icons.payments_outlined,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final montant = _parseMontant(
                              value ?? '',
                            );

                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Le montant proposé est obligatoire.';
                            }

                            if (montant == null) {
                              return 'Saisissez un montant valide.';
                            }

                            if (montant <= 0) {
                              return 'Le montant doit être supérieur à zéro.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _delaiController,
                          textCapitalization:
                              TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText:
                                'Délai d’exécution',
                            hintText:
                                'Exemple : 60 jours',
                            prefixIcon: Icon(
                              Icons.timer_outlined,
                            ),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context)
                              .colorScheme
                              .primary,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Après le dépôt, la soumission sera enregistrée avec le statut « Brouillon » (la référence sera générée automatiquement). Ajoutez au moins un document depuis « Mes soumissions » puis transmettez-la pour la rendre définitive. Une entreprise ne peut déposer qu’une seule soumission pour le même appel d’offres.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: controller.isSubmitting
                      ? null
                      : _deposer,
                  icon: controller.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.send_outlined,
                        ),
                  label: Text(
                    controller.isSubmitting
                        ? 'Dépôt en cours...'
                        : 'Déposer la soumission',
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static double? _parseMontant(
    String valeur,
  ) {
    final texte = valeur
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(',', '.')
        .trim();

    if (texte.isEmpty) {
      return null;
    }

    return double.tryParse(texte);
  }
}
