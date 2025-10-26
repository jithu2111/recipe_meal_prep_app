import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final _connectionStatusController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  Future<void> init() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result.first);

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results.first);
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    // Only emit if status changed
    if (wasOnline != _isOnline) {
      _connectionStatusController.add(_isOnline);
    }
  }

  void dispose() {
    _connectionStatusController.close();
  }
}