import 'package:freezed_annotation/freezed_annotation.dart';

part 'support.freezed.dart';
part 'support.g.dart';

enum SupportType {
  @JsonValue('oneri')
  oneri,
  @JsonValue('sikayet')
  sikayet,
  @JsonValue('talep')
  talep,
}

enum TicketStatus {
  @JsonValue('received')
  received,
  @JsonValue('inReview')
  inReview,
  @JsonValue('answered')
  answered,
  @JsonValue('closed')
  closed,
}

/// `GET /support/tickets` öğesi ("Taleplerim").
@freezed
abstract class SupportTicket with _$SupportTicket {
  const factory SupportTicket({
    required String id,
    required String number,
    required String subject,
    @JsonKey(unknownEnumValue: SupportType.talep) @Default(SupportType.talep) SupportType type,
    required DateTime createdAt,
    @JsonKey(unknownEnumValue: TicketStatus.received) @Default(TicketStatus.received) TicketStatus status,
  }) = _SupportTicket;

  factory SupportTicket.fromJson(Map<String, dynamic> json) => _$SupportTicketFromJson(json);
}

/// `GET /support/faq` öğesi (panelden yönetilir).
@freezed
abstract class FaqItem with _$FaqItem {
  const factory FaqItem({required String id, required String question, required String answer}) = _FaqItem;

  factory FaqItem.fromJson(Map<String, dynamic> json) => _$FaqItemFromJson(json);
}
