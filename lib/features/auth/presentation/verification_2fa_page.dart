import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dashboard/presentation/dashboard_page.dart';
import 'auth_controller.dart';

class Verification2FAPage extends StatefulWidget {
  const Verification2FAPage({super.key});

  @override
  State<Verification2FAPage> createState() =>
      _Verification2FAPageState();
}

class _Verification2FAPageState extends State<Verification2FAPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final result = await context.read<AuthController>().validerDeuxFacteurs(
          code: _codeController.text.trim(),
        );

    if (!mounted) {
      return;
    }

    if (result.isSuccess) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const DashboardPage(),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Double authentification'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 72,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Vérification en deux étapes',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Saisissez le code à 6 chiffres généré par votre application d’authentification.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 8,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Code à 6 chiffres',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      onFieldSubmitted: (_) {
                        if (!authController.isLoading) {
                          _valider();
                        }
                      },
                      validator: (value) {
                        final code = value?.trim() ?? '';

                        if (!RegExp(r'^\d{6}$').hasMatch(code)) {
                          return 'Saisissez les 6 chiffres du code.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed:
                          authController.isLoading ? null : _valider,
                      icon: authController.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        authController.isLoading
                            ? 'Vérification...'
                            : 'Valider',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
