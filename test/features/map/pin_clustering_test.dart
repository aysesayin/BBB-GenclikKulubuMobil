import 'package:bbb_genclik_kulubu_app/features/map/utils/pin_clustering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

typedef _P = ({String id, LatLng at});

LatLng _pos(_P p) => p.at;

void main() {
  group('mercatorPixel', () {
    test('0,0 zoom 0 → karo merkezi', () {
      final px = mercatorPixel(const LatLng(0, 0), 0);
      expect(px.x, closeTo(128, 1e-9));
      expect(px.y, closeTo(128, 1e-9));
    });

    test('her zoom seviyesi ölçeği ikiye katlar', () {
      final a = mercatorPixel(bursaCenter, 10);
      final b = mercatorPixel(bursaCenter, 11);
      expect(b.x, closeTo(a.x * 2, 1e-6));
      expect(b.y, closeTo(a.y * 2, 1e-6));
    });

    test('kuzey daha küçük y değerine sahiptir', () {
      expect(mercatorPixel(const LatLng(41, 29), 12).y, lessThan(mercatorPixel(const LatLng(40, 29), 12).y));
    });
  });

  group('clusterByGrid', () {
    const kozahan = (id: 'kozahan', at: LatLng(40.1838, 29.0641));
    const ulucami = (id: 'ulucami', at: LatLng(40.1842, 29.0616));
    const tayyare = (id: 'tayyare', at: LatLng(40.1856, 29.0593));
    const gemlik = (id: 'gemlik', at: LatLng(40.4318, 29.1563));

    test('boş liste → boş sonuç', () {
      expect(clusterByGrid<_P>(const [], position: _pos, zoom: 13), isEmpty);
    });

    test('düşük zoomda yakın noktalar tek kümede, uzak nokta ayrı', () {
      final clusters = clusterByGrid([kozahan, ulucami, tayyare, gemlik], position: _pos, zoom: 11);
      final big = clusters.firstWhere((c) => c.isCluster);
      expect(big.count, 3);
      expect(big.items.map((e) => e.id), containsAll(['kozahan', 'ulucami', 'tayyare']));
      final single = clusters.firstWhere((c) => !c.isCluster);
      expect(single.first.id, 'gemlik');
      expect(clusters, hasLength(2));
    });

    test('yüksek zoomda kümeler açılır', () {
      final clusters = clusterByGrid([kozahan, ulucami, tayyare], position: _pos, zoom: 18);
      expect(clusters, hasLength(3));
      expect(clusters.every((c) => !c.isCluster), isTrue);
    });

    test('küme merkezi öğelerin ortalamasıdır', () {
      const a = (id: 'a', at: LatLng(40.0, 29.0));
      const b = (id: 'b', at: LatLng(40.0002, 29.0002));
      final c = clusterByGrid([a, b], position: _pos, zoom: 10).single;
      expect(c.center.latitude, closeTo(40.0001, 1e-9));
      expect(c.center.longitude, closeTo(29.0001, 1e-9));
      expect(c.positions(_pos), [a.at, b.at]);
    });

    test('aynı noktadaki öğeler her zoomda birlikte kalır', () {
      const a = (id: 'a', at: LatLng(40.21, 29.04));
      const b = (id: 'b', at: LatLng(40.21, 29.04));
      expect(clusterByGrid([a, b], position: _pos, zoom: 18).single.count, 2);
    });

    test('hücre boyutu büyüdükçe daha çok birleşir', () {
      final small = clusterByGrid([kozahan, ulucami, tayyare], position: _pos, zoom: 15, cellSize: 16);
      final large = clusterByGrid([kozahan, ulucami, tayyare], position: _pos, zoom: 15, cellSize: 4096);
      expect(small.length, greaterThan(large.length));
      expect(large.single.count, 3);
    });

    test('sıra korunur (ilk görülen hücre önce)', () {
      final clusters = clusterByGrid([gemlik, kozahan], position: _pos, zoom: 14);
      expect(clusters.map((c) => c.first.id), ['gemlik', 'kozahan']);
    });
  });
}
