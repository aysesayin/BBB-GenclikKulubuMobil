import 'package:freezed_annotation/freezed_annotation.dart';

part 'watch_video.freezed.dart';
part 'watch_video.g.dart';

/// Sıradaki (kilitli) video.
@freezed
abstract class UpcomingVideo with _$UpcomingVideo {
  const factory UpcomingVideo({required String id, required String title, DateTime? availableAt}) = _UpcomingVideo;

  factory UpcomingVideo.fromJson(Map<String, dynamic> json) => _$UpcomingVideoFromJson(json);
}

/// `GET /buan/videos/current` — İzle Kazan videosu.
@freezed
abstract class WatchVideo with _$WatchVideo {
  const factory WatchVideo({
    required String id,
    required String youtubeId,
    required String title,

    /// "BELEDİYE VİDEOSU" gibi kaynak etiketi (panelden).
    @Default('') String source,
    required int durationSec,
    required int reward,

    /// Sunucunun kabul ettiği izlenen saniye (kaldığı yerden devam).
    @Default(0) int watchedSec,
    @Default(false) bool completed,

    /// Tamamlama eşiği (0–1), varsayılan %90.
    @Default(0.9) double completeRatio,
    DateTime? nextAvailableAt,
    @Default(<UpcomingVideo>[]) List<UpcomingVideo> upNext,
  }) = _WatchVideo;

  factory WatchVideo.fromJson(Map<String, dynamic> json) => _$WatchVideoFromJson(json);
}

/// `POST /buan/videos/{id}/complete` yanıtı.
@freezed
abstract class VideoCompleteResult with _$VideoCompleteResult {
  const factory VideoCompleteResult({@Default(0) int awarded, int? balance, DateTime? nextAvailableAt}) = _VideoCompleteResult;

  factory VideoCompleteResult.fromJson(Map<String, dynamic> json) => _$VideoCompleteResultFromJson(json);
}
