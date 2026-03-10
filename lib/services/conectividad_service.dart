import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConectividadService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// Verifica la conectividad actual
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = result.isNotEmpty && !result.contains(ConnectivityResult.none);
    return _isOnline;
  }

  Future<List<ConnectivityResult>> currentConnections() async {
    return _connectivity.checkConnectivity();
  }

  Future<bool> isUsingMobileData() async {
    final result = await currentConnections();
    return result.contains(ConnectivityResult.mobile) &&
        !result.contains(ConnectivityResult.wifi) &&
        !result.contains(ConnectivityResult.ethernet);
  }

  Future<bool> isUsingUnmeteredConnection() async {
    final result = await currentConnections();
    return result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet);
  }

  /// Configura escucha de cambios de conectividad
  void setupListener(Function(bool) onConnectivityChanged) {
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _isOnline =
          result.isNotEmpty && !result.contains(ConnectivityResult.none);
      onConnectivityChanged(_isOnline);
    });
  }

  /// Detiene la escucha de cambios
  void dispose() {
    _subscription?.cancel();
  }
}
