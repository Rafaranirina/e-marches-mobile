import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/hero_header.dart';
import '../../../shared/widgets/procurement_logo.dart';
import '../../dashboard/presentation/dashboard_page.dart';
import 'auth_controller.dart';
import 'mot_de_passe_oublie_page.dart';
import 'verification_2fa_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final result = await context.read<AuthController>().login(
          email: _emailController.text,
          motDePasse: _passwordController.text,
        );

    if (!mounted) return;

    if (result.isSuccess) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const DashboardPage(),
        ),
      );
      return;
    }

    if (result.requiresTwoFactor) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const Verification2FAPage(),
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/fond_connexion.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.62)),
            ),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HeroHeader(
                    color: Colors.transparent,
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                    child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: CornerTicks(
                        color: scheme.onPrimary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ProcurementLogo(
                      iconSize: 82,
                      wordmarkFontSize: 30,
                      axis: Axis.vertical,
                      inverse: true,
                      // Le vert/menthe de marque se fondait dans l'en-tête
                      // teal (illisible), d'où une couleur de texte forcée
                      // plutôt que le blanc/menthe par défaut. Calculée à
                      // partir de la luminosité réelle de `scheme.primary`
                      // (fond du HeroHeader) plutôt que codée en dur : le
                      // bleu marine choisi pour le thème clair (primary
                      // moyen/sombre) n'a pas la même lisibilité contre le
                      // thème sombre, où `primary` devient un ton clair.
                      couleurTexteForcee:
                          ThemeData.estimateBrightnessForColor(
                                    scheme.primary,
                                  ) ==
                                  Brightness.dark
                              ? Colors.white
                              : const Color(0xFF0A1F44),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -24),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Material(
                        elevation: 3,
                        shadowColor: scheme.shadow.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        color: scheme.surfaceContainerHigh,
                        child: Padding(
                          padding: const EdgeInsets.all(26),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Connexion',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(color: scheme.onSurface),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Accédez à votre espace selon votre rôle.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: scheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  decoration: const InputDecoration(
                                    labelText: 'Adresse e-mail',
                                    prefixIcon: Icon(Icons.mail_outline),
                                  ),
                                  validator: (value) {
                                    final email = value?.trim() ?? '';

                                    if (email.isEmpty) {
                                      return 'Saisissez votre adresse e-mail.';
                                    }

                                    if (!email.contains('@')) {
                                      return 'Adresse e-mail invalide.';
                                    }

                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  onFieldSubmitted: (_) {
                                    if (!authController.isLoading) {
                                      _submit();
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Mot de passe',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      tooltip: _obscurePassword
                                          ? 'Afficher le mot de passe'
                                          : 'Masquer le mot de passe',
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Saisissez votre mot de passe.';
                                    }

                                    return null;
                                  },
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push<void>(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const MotDePasseOubliePage(),
                                        ),
                                      );
                                    },
                                    child: const Text('Mot de passe oublié ?'),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FilledButton.icon(
                                  onPressed:
                                      authController.isLoading ? null : _submit,
                                  icon: authController.isLoading
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: scheme.onPrimary,
                                          ),
                                        )
                                      : const Icon(Icons.arrow_forward),
                                  label: Text(
                                    authController.isLoading
                                        ? 'Connexion...'
                                        : 'Se connecter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'République de Madagascar',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onPrimary,
                        letterSpacing: 0.8,
                      ),
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
