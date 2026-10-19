import 'package:dio/dio.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/profile/support.dart';

/// Destek uç noktaları: öneri / şikâyet / talep, taleplerim, SSS.
class SupportService {
  SupportService(this._client);

  final DioClient _client;

  Future<ApiResult<List<SupportTicket>>> tickets() =>
      _client.get(ApiEndpoints.support, parse: (d) => Json.list(d, SupportTicket.fromJson), cacheKey: 'support.tickets');

  Future<ApiResult<List<FaqItem>>> faq() =>
      _client.get(ApiEndpoints.faq, parse: (d) => Json.list(d, FaqItem.fromJson), cacheKey: 'support.faq');

  /// Ek varsa çok parçalı, yoksa JSON gönderilir.
  Future<ApiResult<SupportTicket>> submit({
    required SupportType type,
    required String topic,
    required String message,
    String? attachmentPath,
    String? attachmentName,
  }) async {
    SupportTicket parse(Object? d) => SupportTicket.fromJson(Json.map(d));
    final fields = {'type': type.name, 'topic': topic, 'message': message};
    if (attachmentPath == null) return _client.post(ApiEndpoints.support, body: fields, parse: parse);
    final form = FormData.fromMap({...fields, 'attachment': await MultipartFile.fromFile(attachmentPath, filename: attachmentName)});
    return _client.upload(ApiEndpoints.support, form: form, parse: parse);
  }
}
