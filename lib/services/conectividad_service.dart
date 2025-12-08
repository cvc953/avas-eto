import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConectividadService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// Verifica la conectividad actual
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    return _isOnline;
  }

  /// Configura escucha de cambios de conectividad
  void setupListener(Function(bool) onConnectivityChanged) {
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
      onConnectivityChanged(_isOnline);
    });
  }

  /// Detiene la escucha de cambios
  void dispose() {
    _subscription?.cancel();
  }
}
