import '../../../core/base/base_view_model.dart';
import '../../../core/router/routes.dart';

/// A7b · Bildirim ön-izin açıklaması: izin kartlarından ÖNCE, sade Türkçe ile
/// "neden bildirim" anlatılır. "Devam" → kart destesi, "Şimdi değil" → İlk günün.
class PrePermissionViewModel extends BaseViewModel {
  PrePermissionViewModel();

  /// "Devam": izin kartı destesine geçilir (OS istemi orada).
  String get continueRoute => Routes.permissions;

  /// "Şimdi değil": izin istenmez, doğrudan ilk gün listesi.
  /// TODO(varsayım): Atlayan kullanıcıya bildirim izni Keşfet'te sonraki açılışta tekrar hatırlatılır (profil / home özelliği).
  String get skipRoute => Routes.firstDay;
}
