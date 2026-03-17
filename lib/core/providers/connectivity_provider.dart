import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/legacy.dart';

enum ConnectionStatus { online, offline }

class ConnectivityNotifier extends StateNotifier<ConnectionStatus> {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  ConnectivityNotifier() : super(ConnectionStatus.online) {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      if (results.isEmpty || results.contains(ConnectivityResult.none)) {
        state = ConnectionStatus.offline;
      } else {
        state = ConnectionStatus.online;
      }
    });

    // Vérification initiale
    _checkInitial();
  }

  Future<void> _checkInitial() async {
    final results = await _connectivity.checkConnectivity();
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      state = ConnectionStatus.offline;
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectionStatus>((ref) {
  return ConnectivityNotifier();
});
