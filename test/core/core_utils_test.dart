import 'package:bbb_genclik_kulubu_app/core/network/interceptors/mock_interceptor.dart';
import 'package:bbb_genclik_kulubu_app/core/utils/formatters.dart';
import 'package:bbb_genclik_kulubu_app/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr'));

  group('Validators.tckn', () {
    test('geçerli TCKN kabul edilir', () => expect(Validators.isValidTckn('10000000146'), isTrue));
    test('0 ile başlayan reddedilir', () => expect(Validators.isValidTckn('01234567890'), isFalse));
    test('kontrol hanesi hatalı reddedilir', () => expect(Validators.isValidTckn('10000000147'), isFalse));
    test('uzunluk hatası', () => expect(Validators.tckn('123'), ValidationIssue.tcknLength));
  });

  group('Validators diğer', () {
    test('telefon', () {
      expect(Validators.phone('0532 000 00 00'), isNull);
      expect(Validators.phone('532 000 00 00'), isNull);
      expect(Validators.phone('0212 000 00 00'), ValidationIssue.phoneInvalid);
    });
    test('e-posta', () => expect(Validators.email('a@b.co'), isNull));
    test('yaş', () => expect(Validators.ageOn(DateTime(2010, 10, 17), DateTime(2026, 10, 16)), 15));
  });

  group('Fmt', () {
    test('binlik ayırıcı nokta', () => expect(Fmt.number(12450), '12.450'));
    test('işaretli', () {
      expect(Fmt.signed(2000), '+2.000');
      expect(Fmt.signed(-8000), '−8.000');
    });
    test('TCKN maskesi', () => expect(Fmt.maskTckn('12345678901'), '1234*****01'));
    test('mm:ss', () => expect(Fmt.mmss(const Duration(seconds: 274)), '04:34'));
    test('Türkçe büyük harf', () {
      expect(trUpper('istanbul ılık'), 'İSTANBUL ILIK');
      expect(trLower('IĞDIR İnegöl'), 'ığdır inegöl');
    });
  });

  group('MockInterceptor.candidates', () {
    test('GET düz yol', () => expect(MockInterceptor.candidates('/buan/wallet', 'GET').first, 'assets/mock/buan.wallet.json'));
    test('id joker sırası', () {
      final c = MockInterceptor.candidates('/opportunities/opp-1/claim', 'POST');
      expect(c.first, 'assets/mock/opportunities.opp-1.claim.post.json');
      expect(c, contains('assets/mock/opportunities._.claim.post.json'));
      expect(c.indexOf('assets/mock/opportunities._.claim.post.json'), lessThan(c.indexOf('assets/mock/opportunities._._.post.json')));
    });
    test('sorgu yok sayılır', () => expect(MockInterceptor.candidates('/events?date=1', 'GET'), ['assets/mock/events.json']));
  });
}
