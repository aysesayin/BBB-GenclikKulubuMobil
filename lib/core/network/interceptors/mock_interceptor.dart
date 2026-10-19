import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../api_endpoints.dart';

/// `ApiConfig.useMock == true` iken istekleri `assets/mock/` altındaki JSON
/// dosyalarından yanıtlar; backend hazır olmadan tüm uygulama demo edilebilir.
///
/// Dosya adı kuralı (düz klasör, segmentler `.` ile birleşir):
/// - `GET  /buan/wallet`                → `buan.wallet.json`
/// - `GET  /opportunities/opp-1`        → `opportunities.opp-1.json`, yoksa `opportunities._.json`
/// - `POST /opportunities/opp-1/claim`  → `opportunities.opp-1.claim.post.json`, `opportunities._.claim.post.json`,
///                                        sonra aynıları `.post` olmadan.
/// `_` herhangi bir id segmentinin yerini tutar. Sorgu parametreleri yok sayılır.
/// Dosya bulunamazsa: GET → 404 zarfı, diğer metodlar → `{success:true,data:{}}`.
/// Dosya içeriği standart zarftır; `"_status": 409` gibi bir alan hata simülasyonu yapar.
class MockInterceptor extends Interceptor {
  MockInterceptor({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  Set<String>? _assets;

  static const _dir = 'assets/mock/';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!ApiConfig.useMock) return handler.next(options);
    await Future<void>.delayed(ApiConfig.mockLatency);
    final assets = _assets ??= await _loadManifest();
    final method = options.method.toUpperCase();
    final file = candidates(options.path, method).firstWhere(assets.contains, orElse: () => '');

    if (file.isEmpty) {
      if (kDebugMode) debugPrint('[mock] eşleşme yok: $method ${options.path}');
      final notFound = method == 'GET';
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: notFound ? 404 : 200,
          data: notFound
              ? {'success': false, 'data': null, 'message': 'mock bulunamadı', 'errors': <Object>[]}
              : {'success': true, 'data': <String, Object>{}, 'message': 'mock', 'errors': <Object>[]},
        ),
        true,
      );
    }

    final json = jsonDecode(await _bundle.loadString(file)) as Map<String, dynamic>;
    final status = (json.remove('_status') as num?)?.toInt() ?? 200;
    final response = Response<Object?>(requestOptions: options, statusCode: status, data: json);
    if (status >= 400) {
      return handler.reject(
        DioException(requestOptions: options, response: response, type: DioExceptionType.badResponse),
        true,
      );
    }
    handler.resolve(response, true);
  }

  Future<Set<String>> _loadManifest() async {
    final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
    return manifest.listAssets().where((a) => a.startsWith(_dir)).toSet();
  }

  /// Aday dosya yolları, en özelden en genele.
  @visibleForTesting
  static List<String> candidates(String path, String method) {
    final clean = Uri.parse(path).path;
    final segs = clean.split('/').where((s) => s.isNotEmpty).toList();
    if (segs.isEmpty) return const [];
    final variants = <List<String>>[];
    final n = segs.length - 1; // ilk segment hiç joker olmaz
    for (var wild = 0; wild <= n; wild++) {
      for (var mask = 0; mask < (1 << n); mask++) {
        if (_bits(mask) != wild) continue;
        variants.add([
          segs.first,
          for (var i = 0; i < n; i++) (mask & (1 << (n - 1 - i))) != 0 ? '_' : segs[i + 1],
        ]);
      }
    }
    final m = method.toLowerCase();
    return [
      for (final v in variants) ...[
        if (m != 'get') '$_dir${v.join('.')}.$m.json',
        '$_dir${v.join('.')}.json',
      ],
    ];
  }

  static int _bits(int v) {
    var c = 0;
    for (var x = v; x > 0; x >>= 1) {
      c += x & 1;
    }
    return c;
  }
}
