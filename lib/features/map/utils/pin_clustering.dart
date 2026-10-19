import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Bursa merkezi (Kent Meydanı civarı) — konum yokken varsayılan odak.
const bursaCenter = LatLng(40.1885, 29.0610);

/// Web Mercator piksel izdüşümü (256 px karo, flutter_map/OSM ile aynı).
math.Point<double> mercatorPixel(LatLng p, double zoom) {
  final scale = 256 * math.pow(2, zoom).toDouble();
  final x = (p.longitude + 180) / 360 * scale;
  final lat = p.latitude.clamp(-85.05112878, 85.05112878) * math.pi / 180;
  final y = (1 - math.log(math.tan(lat) + 1 / math.cos(lat)) / math.pi) / 2 * scale;
  return math.Point(x, y);
}

/// Izgara kümesi: tek öğe → normal pin, birden çok → "+N" balonu.
class PinCluster<T> {
  PinCluster(this.items, this.center);

  final List<T> items;

  /// Öğelerin ortalama konumu (balonun yeri).
  final LatLng center;

  bool get isCluster => items.length > 1;
  int get count => items.length;
  T get first => items.first;

  /// Kümeye yakınlaşmak için sınır noktaları.
  List<LatLng> positions(LatLng Function(T) position) => items.map(position).toList();
}

/// Basit ızgara kümeleme: öğeler [zoom] seviyesinde piksel uzayına izdüşürülür ve
/// [cellSize] px'lik hücrelere düşenler tek kümede toplanır. Sıra korunur (ilk görülen hücre önce).
///
/// Harici paket yoktur; O(n). Hücre sınırına denk gelen iki yakın nokta ayrı kalabilir
/// (ızgara kümelemenin bilinen ödünleşimi) — pin boyutu 42 px, hücre 64 px olduğundan görsel çakışma azdır.
List<PinCluster<T>> clusterByGrid<T>(
  Iterable<T> items, {
  required LatLng Function(T) position,
  required double zoom,
  double cellSize = 64,
}) {
  assert(cellSize > 0);
  final cells = <String, List<T>>{}; // ekleme sırasını korur
  for (final item in items) {
    final px = mercatorPixel(position(item), zoom);
    final key = '${(px.x / cellSize).floor()}:${(px.y / cellSize).floor()}';
    (cells[key] ??= <T>[]).add(item);
  }
  return [
    for (final group in cells.values) PinCluster<T>(List.unmodifiable(group), _centroid(group.map(position))),
  ];
}

LatLng _centroid(Iterable<LatLng> points) {
  var lat = 0.0, lng = 0.0, n = 0;
  for (final p in points) {
    lat += p.latitude;
    lng += p.longitude;
    n++;
  }
  return LatLng(lat / n, lng / n);
}
