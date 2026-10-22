import 'dart:convert';
import 'dart:io';

import 'package:bbb_genclik_kulubu_app/core/network/dio_client.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/account_settings.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/child_profile.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/coupon.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/delete_request.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/discount.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/profile_stats.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/support.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/user_profile.dart';
import 'package:bbb_genclik_kulubu_app/data/services/coupon_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock JSON dosyalarının profil modelleriyle çözülebildiğini doğrular.
void main() {
  Object? data(String name) {
    final file = File('assets/mock/$name');
    expect(file.existsSync(), isTrue, reason: name);
    return (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>)['data'];
  }

  test('profil mock dosyaları modellere uyar', () {
    final me = UserProfile.fromJson(Json.map(data('users.me.json')));
    expect(me.displayTckn, '1234*****90');
    expect(me.buanBalance, 12450);
    final stats = ProfileStats.fromJson(Json.map(data('users.me.stats.json')));
    expect(stats.featuredBadges, hasLength(3));
    expect(stats.districtRank, 14);
    final receipt = DeleteRequestReceipt.fromJson(Json.map(data('users.me.delete-request.post.json')));
    expect(receipt.requestNo, 'KVKK-2026-048213');
    expect(receipt.processUntil, DateTime(2026, 11, 21));
    expect(NotificationPrefs.fromJson(Json.map(data('users.me.preferences.json'))).announcements, isFalse);
    expect(ContactChallenge.fromJson(Json.map(data('users.me.contact.put.json'))).codeLength, 6);
    expect(Json.list(data('users.me.children.json'), ChildProfile.fromJson), hasLength(2));
    expect(ChildProfile.fromJson(Json.map(data('users.me.children.post.json'))).id, 'chd-yeni');
    expect(Json.list(data('discount-types.json'), DiscountType.fromJson), hasLength(6));
    expect(UserDiscount.fromJson(Json.map(data('users.me.discounts.post.json'))).status, DiscountStatus.pending);
    expect(Json.list(data('support.tickets.json'), SupportTicket.fromJson).first.status, TicketStatus.answered);
    expect(SupportTicket.fromJson(Json.map(data('support.tickets.post.json'))).number, '25010');
    expect(Json.list(data('support.faq.json'), FaqItem.fromJson), hasLength(3));
    expect(Json.list(data('coupons.movements.json'), CouponMovement.fromJson), hasLength(3));
  });

  test('diğer grupların paylaşılan mock dosyaları (varsa) uyumlu', () {
    if (File('assets/mock/users.me.discounts.json').existsSync()) {
      expect(Json.list(data('users.me.discounts.json'), UserDiscount.fromJson), isNotEmpty);
    }
    if (File('assets/mock/coupons.json').existsSync()) {
      expect(CouponService.parseWallet(data('coupons.json')).items, isNotEmpty);
    }
  });
}
