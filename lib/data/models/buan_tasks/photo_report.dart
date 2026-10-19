import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo_report.freezed.dart';
part 'photo_report.g.dart';

@freezed
abstract class ReportCategory with _$ReportCategory {
  const factory ReportCategory({required String id, required String label}) = _ReportCategory;

  factory ReportCategory.fromJson(Map<String, dynamic> json) => _$ReportCategoryFromJson(json);
}

/// Gönderi türü (Güzellik / Sorun / Fikir) — etiket, ödül ve kategoriler panelden.
@freezed
abstract class PhotoReportType with _$PhotoReportType {
  const factory PhotoReportType({
    required String id,
    required String label,
    required int reward,
    @Default(true) bool requiresPhoto,
    @Default(<ReportCategory>[]) List<ReportCategory> categories,
  }) = _PhotoReportType;

  factory PhotoReportType.fromJson(Map<String, dynamic> json) => _$PhotoReportTypeFromJson(json);
}

enum ReportStatus {
  @JsonValue('approved')
  approved,
  @JsonValue('pending')
  pending,
  @JsonValue('rejected')
  rejected,
}

/// Gönderilerim satırı (moderasyon durumuyla).
@freezed
abstract class PhotoReport with _$PhotoReport {
  const factory PhotoReport({
    required String id,
    required String title,
    required DateTime createdAt,
    @Default('') String typeLabel,
    @Default(ReportStatus.pending) ReportStatus status,

    /// "Belediyeye iletildi", "Görsel net değil" gibi moderatör notu.
    String? statusNote,
    @Default(0) int reward,
    String? thumbnailUrl,
  }) = _PhotoReport;

  factory PhotoReport.fromJson(Map<String, dynamic> json) => _$PhotoReportFromJson(json);
}

/// Gönderim taslağı (multipart). JSON değildir.
class PhotoReportDraft {
  const PhotoReportDraft({
    required this.typeId,
    required this.categoryId,
    required this.note,
    this.photo,
    this.photoName,
    this.latitude,
    this.longitude,
  });

  final String typeId, categoryId, note;
  final Uint8List? photo;
  final String? photoName;
  final double? latitude, longitude;
}
