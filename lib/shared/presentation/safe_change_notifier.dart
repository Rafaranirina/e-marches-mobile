import 'package:flutter/foundation.dart';

/// [ChangeNotifier] qui ignore silencieusement les appels à
/// [notifyListeners] survenant après [dispose] (ex. réponse réseau reçue
/// après que l'utilisateur a quitté l'écran), au lieu de planter avec
/// "A ... was used after being disposed.".
abstract class SafeChangeNotifier extends ChangeNotifier {
  bool _disposed = false;

  bool get disposed => _disposed;

  @override
  void notifyListeners() {
    if (_disposed) {
      return;
    }
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
