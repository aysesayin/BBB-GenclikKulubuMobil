import 'dart:convert';
import 'dart:io';

import 'package:bbb_genclik_kulubu_app/core/network/dio_client.dart';
import 'package:bbb_genclik_kulubu_app/data/models/services/application.dart';
import 'package:bbb_genclik_kulubu_app/data/models/services/benefits.dart';
import 'package:bbb_genclik_kulubu_app/data/models/services/cart.dart';
import 'package:bbb_genclik_kulubu_app/data/models/services/facility.dart';
import 'package:bbb_genclik_kulubu_app/data/models/services/session.dart';
import 'package:bbb_genclik_kulubu_app/data/models/services/sports.dart';
import 'package:flutter_test/flutter_test.dart';

Object? _data(String name) => (jsonDecode(File('assets/mock/$name').readAsStringSync()) as Map)['data'];

void main() {
  test('hizmetler mock dosyaları modellere çözülür', () {
    expect(PoolCatalog.fromJson(Json.map(_data('services.pools.json'))).items, hasLength(4));
    for (final f in [
      'services.facilities.fac-fethiye.items.json',
      'services.facilities.fac-mihrapli.items.json',
      'services.facilities._.items.json',
    ]) {
      expect(Json.list(_data(f), ServiceItem.fromJson), isNotEmpty);
    }
    final daily = SessionWeek.fromJson(Json.map(_data('services.items.itm-fethiye-gunluk.sessions.json')));
    expect(daily.slots.where((s) => s.status == SlotStatus.holiday), isNotEmpty);
    expect(daily.participants.map((p) => p.relation), [Relation.self, Relation.child]);
    SessionWeek.fromJson(Json.map(_data('services.items.itm-mihrapli-kurs.sessions.json')));
    SessionWeek.fromJson(Json.map(_data('services.items._.sessions.json')));
    expect(SportsCatalog.fromJson(Json.map(_data('services.sports-branches.json'))).branches, hasLength(12));
    expect(Json.list(_data('services.tennis-products.json'), TennisProduct.fromJson), hasLength(8));
    final cart = Cart.fromJson(Json.map(_data('cart.json')));
    expect(cart.expiresAt!.difference(cart.serverTime!), const Duration(minutes: 5));
    CartHold.fromJson(Json.map(_data('cart.hold.post.json')));
    expect(CheckoutResult.fromJson(Json.map(_data('cart.checkout.post.json'))).paymentUrl, isNotNull);
    expect(Json.list(_data('users.me.discounts.json'), EligibleDiscount.fromJson).first.usable, isTrue);
    expect(CouponWallet.fromJson(Json.map(_data('coupons.json'))).balance, 30);
    final apps = Json.list(_data('applications.json'), Application.fromJson);
    expect(apps.where((a) => a.isActive), hasLength(3));
    CancelResult.fromJson(Json.map(_data('applications._.cancel.post.json')));
  });
}
