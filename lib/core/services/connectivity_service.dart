import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Connectivity Service Class
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result.any((r) => 
      r == ConnectivityResult.mobile || 
      r == ConnectivityResult.wifi ||
      r == ConnectivityResult.ethernet
    );
  }

  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((result) {
      return result.any((r) => 
        r == ConnectivityResult.mobile || 
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet
      );
    });
  }
}

// Provider for connectivity status
final connectivityProvider = StreamProvider<bool>((ref) {
  return ConnectivityService().onConnectivityChanged;
});

// Provider for current connectivity state
final isOnlineProvider = Provider<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityProvider);
  return connectivityAsync.when(
    data: (isConnected) => isConnected,
    loading: () => true, // Assume online while loading
    error: (error, stackTrace) => false,
  );
});
