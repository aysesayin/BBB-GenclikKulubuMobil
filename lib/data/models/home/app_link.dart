import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_link.freezed.dart';
part 'app_link.g.dart';

/// Panelden yönetilen içerik bağlantısı (banner, kısayol, hikâye CTA'sı, bildirim).
///
/// `type` bir hedef anahtarıdır (`opportunity`, `event`, `place`, `map`, `steps` …);
/// `id` yalnız detay hedeflerinde dolu gelir. Rota eşlemesi
/// `features/home/home_links.dart` içindedir.
@freezed
abstract class AppLink with _$AppLink {
  const factory AppLink({required String type, String? id}) = _AppLink;

  factory AppLink.fromJson(Map<String, dynamic> json) => _$AppLinkFromJson(json);
}
