import '../../core/network/api_result.dart';
import '../models/stories/story.dart';
import '../services/story_service.dart';

abstract interface class StoryRepository {
  Future<ApiResult<Story>> detail(String id);
  Future<ApiResult<void>> markSeen(String id);
}

class StoryRepositoryImpl implements StoryRepository {
  StoryRepositoryImpl(this._service);

  final StoryService _service;

  @override
  Future<ApiResult<Story>> detail(String id) => _service.detail(id);

  @override
  Future<ApiResult<void>> markSeen(String id) => _service.markSeen(id);
}
