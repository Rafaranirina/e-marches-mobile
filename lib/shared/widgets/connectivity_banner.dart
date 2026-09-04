import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Enveloppe [child] avec une bannière persistante affichée en haut de
/// l'écran lorsque l'appareil n'a plus de connexion réseau (Wi-Fi/données
/// mobiles) — évite de laisser chaque écran afficher son propre message
/// Dio générique de connexion impossible sans indication globale.
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<ConnectivityBanner> createState() =>
      _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _horsLigne = false;

  @override
  void initState() {
    super.initState();

    Connectivity().checkConnectivity().then(_mettreAJour);

    Connectivity()
        .onConnectivityChanged
        .listen(_mettreAJour);
  }

  void _mettreAJour(List<ConnectivityResult> resultats) {
    final horsLigne = resultats.every(
      (resultat) => resultat == ConnectivityResult.none,
    );

    if (!mounted || horsLigne == _horsLigne) {
      return;
    }

    setState(() {
      _horsLigne = horsLigne;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_horsLigne)
          Material(
            color: Theme.of(context).colorScheme.error,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi_off_outlined,
                      size: 18,
                      color: Theme.of(context)
                          .colorScheme
                          .onError,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Aucune connexion Internet. '
                        'Certaines actions sont indisponibles.',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onError,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
