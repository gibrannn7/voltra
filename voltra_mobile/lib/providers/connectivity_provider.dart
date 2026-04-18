import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _hasInternet = true;
  bool get hasInternet => _hasInternet;

  ConnectivityProvider() {
    _initConnectivity();
    Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    bool previousStatus = _hasInternet;
    
    if (results.isEmpty || results.first == ConnectivityResult.none) {
      _hasInternet = false;
    } else {
      _hasInternet = true;
    }

    if (previousStatus != _hasInternet) {
      notifyListeners();
    }
  }
}