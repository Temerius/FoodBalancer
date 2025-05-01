import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkUtil {
  // Singleton instance
  static final NetworkUtil _instance = NetworkUtil._internal();
  factory NetworkUtil() => _instance;
  NetworkUtil._internal();

  // Connectivity instance
  final Connectivity _connectivity = Connectivity();

  // Stream controllers
  final _connectionStatusController = StreamController<bool>.broadcast();

  // Stream getters
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  // Connection status
  bool _hasConnection = true;
  bool get hasConnection => _hasConnection;

  // Initialize
  Future<void> initialize() async {
    // Check initial connection
    await checkConnection();

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  // Check connection
  Future<bool> checkConnection() async {
    bool previousConnection = _hasConnection;

    try {
      // First check connectivity status
      final connectivityResult = await _connectivity.checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        _hasConnection = false;
      } else {
        // Then actually try to connect to a known server
        final result = await InternetAddress.lookup('google.com');
        _hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      }
    } on SocketException catch (_) {
      _hasConnection = false;
    } catch (_) {
      _hasConnection = false;
    }

    // If connection status changed, notify listeners
    if (previousConnection != _hasConnection) {
      _connectionStatusController.add(_hasConnection);
    }

    return _hasConnection;
  }

  // Handle connectivity change
  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    if (result == ConnectivityResult.none) {
      _hasConnection = false;
      _connectionStatusController.add(false);
    } else {
      // Double-check we actually have internet access
      final hasConnection = await checkConnection();
      _connectionStatusController.add(hasConnection);
    }
  }

  // Dispose
  void dispose() {
    _connectionStatusController.close();
  }
}