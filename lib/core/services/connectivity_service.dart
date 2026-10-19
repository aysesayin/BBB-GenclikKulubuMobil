import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Bağlantı durumu (çevrimdışı şeridi için). Kesin doğruluk için istek
/// hatası ([NetworkException]) esas alınır; bu yalnız ipucudur.
class ConnectivityService {
  ConnectivityService([Connectivity? c]) : _c = c ?? Connectivity();

  final Connectivity _c;
  final ValueNotifier<bool> online = ValueNotifier(true);
  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<void> start() async {
    try {
      _apply(await _c.checkConnectivity());
      _sub = _c.onConnectivityChanged.listen(_apply);
    } on Object {
      online.value = true; // eklenti yoksa (test/web) çevrimiçi varsay
    }
  }

  void _apply(List<ConnectivityResult> r) => online.value = r.any((e) => e != ConnectivityResult.none);

  Future<void> dispose() async => _sub?.cancel();
}
