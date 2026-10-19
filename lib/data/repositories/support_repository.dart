import '../../core/network/api_result.dart';
import '../models/profile/support.dart';
import '../services/support_service.dart';

abstract interface class SupportRepository {
  Future<ApiResult<List<SupportTicket>>> tickets();
  Future<ApiResult<List<FaqItem>>> faq();
  Future<ApiResult<SupportTicket>> submit({
    required SupportType type,
    required String topic,
    required String message,
    String? attachmentPath,
    String? attachmentName,
  });
}

class SupportRepositoryImpl implements SupportRepository {
  SupportRepositoryImpl(this._service);

  final SupportService _service;

  @override
  Future<ApiResult<List<SupportTicket>>> tickets() => _service.tickets();

  @override
  Future<ApiResult<List<FaqItem>>> faq() => _service.faq();

  @override
  Future<ApiResult<SupportTicket>> submit({
    required SupportType type,
    required String topic,
    required String message,
    String? attachmentPath,
    String? attachmentName,
  }) => _service.submit(type: type, topic: topic, message: message, attachmentPath: attachmentPath, attachmentName: attachmentName);
}
