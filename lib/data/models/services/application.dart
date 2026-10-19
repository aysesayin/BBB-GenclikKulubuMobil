import 'package:freezed_annotation/freezed_annotation.dart';

part 'application.freezed.dart';
part 'application.g.dart';

enum ApplicationStatus { approved, accepted, pendingPayment, waitlist, attended, cancelled, rejected, unknown }

/// Vazgeçme düğmesinin türü: İptal / Vazgeç / İptal talebi.
enum CancelKind { cancel, withdraw, request }

enum ApplicationSource { service, event, unknown }

@freezed
abstract class ApplicationTicket with _$ApplicationTicket {
  const factory ApplicationTicket({required String qrToken, @Default('') String code}) = _ApplicationTicket;

  factory ApplicationTicket.fromJson(Map<String, dynamic> json) => _$ApplicationTicketFromJson(json);
}

/// `GET /applications?status=` — kota bilgisi ([quotaNote]) aynı yanıtta.
@freezed
abstract class Application with _$Application {
  const Application._();

  const factory Application({
    required String id,
    required String title,
    @Default('') String subtitle,
    @JsonKey(unknownEnumValue: ApplicationStatus.unknown) @Default(ApplicationStatus.unknown) ApplicationStatus status,
    @Default(false) bool paid,
    DateTime? paymentDueAt,
    int? earnedBuan,

    /// İptal sonrası tanımlanan bakiye kuponu (rapor telafisi).
    num? couponAmount,
    @Default(false) bool medicalMakeUp,
    String? quotaNote,
    String? note,
    ApplicationTicket? ticket,
    @Default(true) bool canCancel,
    @JsonKey(unknownEnumValue: CancelKind.cancel) @Default(CancelKind.cancel) CancelKind cancelKind,
    @JsonKey(unknownEnumValue: ApplicationSource.unknown) @Default(ApplicationSource.service) ApplicationSource sourceType,
    @Default('') String sourceId,
    @Default(3) int tile,
    @Default('wave') String icon,
  }) = _Application;

  factory Application.fromJson(Map<String, dynamic> json) => _$ApplicationFromJson(json);

  bool get isActive => switch (status) {
        ApplicationStatus.approved ||
        ApplicationStatus.accepted ||
        ApplicationStatus.pendingPayment ||
        ApplicationStatus.waitlist =>
          true,
        _ => false,
      };
}

/// `POST /applications/{id}/cancel` yanıtı.
@freezed
abstract class CancelResult with _$CancelResult {
  const factory CancelResult({
    @JsonKey(unknownEnumValue: ApplicationStatus.unknown) @Default(ApplicationStatus.cancelled) ApplicationStatus status,
    num? couponAmount,
  }) = _CancelResult;

  factory CancelResult.fromJson(Map<String, dynamic> json) => _$CancelResultFromJson(json);
}
