import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/dashboard/presentation/dashboard_page.dart';
import 'shared/widgets/connectivity_banner.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final authController = AuthController();

  // Sur un 401 hors login/2FA (token expiré ou révoqué en cours de route),
  // déconnecte proprement l'utilisateur — le Consumer<AuthController> du
  // MaterialApp bascule alors automatiquement sur LoginPage.
  ApiClient.onUnauthorized = () {
    authController.logout();
  };

  runApp(
    ChangeNotifierProvider.value(
      value: authController,
      child: const EMarchesApp(),
    ),
  );
}

class EMarchesApp extends StatefulWidget {
  const EMarchesApp({super.key});

  @override
  State<EMarchesApp> createState() => _EMarchesAppState();
}

class _EMarchesAppState extends State<EMarchesApp> {
  @override
  void initState() {
    super.initState();

    // Si un token est encore stocké depuis un lancement précédent, on
    // revalide la session auprès du serveur plutôt que de forcer une
    // reconnexion systématique. Différé après la première frame : appeler
    // notifyListeners() pendant que l'arbre de widgets est encore en train
    // de se construire (depuis initState) provoque une erreur Flutter
    // ("Failed assertion: '!_dirty' is not true").
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<AuthController>().restaurerSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'e-Marchés Madagascar',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        return ConnectivityBanner(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: Consumer<AuthController>(
        builder: (context, authController, child) {
          if (authController.isRestoring) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (authController.isAuthenticated) {
            return const DashboardPage();
          }

          return const LoginPage();
        },
      ),
    );
  }
}
