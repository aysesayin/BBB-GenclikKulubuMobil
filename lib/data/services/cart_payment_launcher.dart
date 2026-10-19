import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_endpoints.dart';

enum PaymentOutcome { success, pending, failed }

/// 3D Secure ödeme sayfasını açar.
abstract interface class PaymentLauncher {
  Future<PaymentOutcome> open(String paymentUrl);
}

/// TODO(varsayım): webview_flutter kurulu değil; 3D Secure sayfası url_launcher ile uygulama içi
/// tarayıcıda açılır. Sonuç, banka dönüşündeki deep link / sipariş durumu sorgusuyla kesinleşmeli.
/// Mock modunda ödeme başarılı sayılır.
class UrlPaymentLauncher implements PaymentLauncher {
  const UrlPaymentLauncher();

  @override
  Future<PaymentOutcome> open(String paymentUrl) async {
    if (ApiConfig.useMock) return PaymentOutcome.success;
    final uri = Uri.tryParse(paymentUrl);
    if (uri == null) return PaymentOutcome.failed;
    final ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    return ok ? PaymentOutcome.pending : PaymentOutcome.failed;
  }
}
