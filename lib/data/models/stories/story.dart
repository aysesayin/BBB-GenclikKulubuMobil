import 'package:freezed_annotation/freezed_annotation.dart';

import '../home/app_link.dart';

part 'story.freezed.dart';
part 'story.g.dart';

/// `GET /stories/{id}` — bir hikâye ve segmentleri (her segment 6 sn).
@freezed
abstract class Story with _$Story {
  const factory Story({
    required String id,
    @Default('') String author,
    @Default('') String authorInitials,
    required DateTime publishedAt,
    @Default(<StorySlide>[]) List<StorySlide> slides,
  }) = _Story;

  factory Story.fromJson(Map<String, dynamic> json) => _$StoryFromJson(json);
}

@freezed
abstract class StorySlide with _$StorySlide {
  const factory StorySlide({
    required String id,
    @Default('') String tag,
    required String title,
    @Default('') String body,
    String? ctaLabel,
    AppLink? link,

    /// Zemin teması: teal · buan · fresh.
    @Default('teal') String theme,
  }) = _StorySlide;

  factory StorySlide.fromJson(Map<String, dynamic> json) => _$StorySlideFromJson(json);
}
