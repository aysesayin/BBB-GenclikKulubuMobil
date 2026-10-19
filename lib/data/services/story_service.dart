import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/stories/story.dart';

/// Hikâyeler: detay + görüldü bildirimi.
class StoryService {
  StoryService(this._client);

  final DioClient _client;

  Future<ApiResult<Story>> detail(String id) =>
      _client.get(ApiEndpoints.storyDetail(id), parse: (d) => Story.fromJson(Json.map(d)), cacheKey: 'story.$id');

  Future<ApiResult<void>> markSeen(String id) => _client.post(ApiEndpoints.storySeen(id), parse: Json.ignore);
}
