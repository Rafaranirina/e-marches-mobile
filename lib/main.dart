import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/dashboard/presentation/dashboard_page.dart';

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
    // reconnexion systématique.
    context.read<AuthController>().restaurerSession();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'e-Marchés Madagascar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006B3C),
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
        ),
      ),
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
