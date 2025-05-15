import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkUtil {
  
  static final NetworkUtil _instance = NetworkUtil._internal();
  factory NetworkUtil() => _instance;
  NetworkUtil._internal();

  
  final Connectivity _connectivity = Connectivity();

  
  final _connectionStatusController = StreamController<bool>.broadcast();

  
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  
  bool _hasConnection = true;
  bool get hasConnection => _hasConnection;

  
  Future<void> initialize() async {
    
    await checkConnection();

    
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  
  Future<bool> checkConnection() async {
    bool previousConnection = _hasConnection;

    try {
      
      final connectivityResult = await _connectivity.checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        _hasConnection = false;
      } else {
        
        final result = await InternetAddress.lookup('google.com');
        _hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      }
    } on SocketException catch (_) {
      _hasConnection = false;
    } catch (_) {
      _hasConnection = false;
    }

    
    if (previousConnection != _hasConnection) {
      _connectionStatusController.add(_hasConnection);
    }

    return _hasConnection;
  }

  
  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    if (result == ConnectivityResult.none) {
      _hasConnection = false;
      _connectionStatusController.add(false);
    } else {
      
      final hasConnection = await checkConnection();
      _connectionStatusController.add(hasConnection);
    }
  }

  
  void dispose() {
    _connectionStatusController.close();
  }
}