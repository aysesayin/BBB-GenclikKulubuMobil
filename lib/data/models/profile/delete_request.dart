import 'package:freezed_annotation/freezed_annotation.dart';

part 'delete_request.freezed.dart';
part 'delete_request.g.dart';

/// `POST /users/me/delete-request` yanıtı: KVKK silme talebi makbuzu.
// TODO(varsayım): Backend sözleşmesi netleşmedi; `requestNo` kullanıcıya gösterilen talep numarası,
// `processUntil` 30 günlük yasal sürecin bitiş tarihi, `emailSent` bilgilendirme e-postası gönderildi mi.
@freezed
abstract class DeleteRequestReceipt with _$DeleteRequestReceipt {
  const factory DeleteRequestReceipt({
    @Default('') String requestId,
    @Default('') String requestNo,
    @Default('received') String status,
    DateTime? processUntil,
    @Default(true) bool emailSent,
  }) = _DeleteRequestReceipt;

  factory DeleteRequestReceipt.fromJson(Map<String, dynamic> json) => _$DeleteRequestReceiptFromJson(json);
}
