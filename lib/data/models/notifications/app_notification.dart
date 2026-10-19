import 'package:freezed_annotation/freezed_annotation.dart';

import '../home/app_link.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

/// Bildirim kategorisi (chip filtresi).
enum NotificationCategory { earn, opportunity, event, reservation, announcement }

/// `GET /notifications?cat=` satırı.
@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    @JsonKey(unknownEnumValue: NotificationCategory.announcement) required NotificationCategory category,
    required String title,
    @Default('') String body,
    required DateTime createdAt,
    @Default(false) bool unread,

    /// İkon anahtarı (bkz. `HomeIcons.of`).
    @Default('megaphone') String icon,
    @Default(4) int tone,
    AppLink? link,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) => _$AppNotificationFromJson(json);
}
