import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz.freezed.dart';
part 'quiz.g.dart';

@freezed
abstract class QuizOption with _$QuizOption {
  const factory QuizOption({required String id, required String label}) = _QuizOption;

  factory QuizOption.fromJson(Map<String, dynamic> json) => _$QuizOptionFromJson(json);
}

/// Soru. Doğru cevap istemciye GÖNDERİLMEZ (anti-cheat).
@freezed
abstract class QuizQuestion with _$QuizQuestion {
  const factory QuizQuestion({required String id, required String text, required List<QuizOption> options, String? imageUrl}) = _QuizQuestion;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => _$QuizQuestionFromJson(json);
}

/// `GET /buan/quizzes/active`.
@freezed
abstract class Quiz with _$Quiz {
  const factory Quiz({
    required String id,
    required String title,
    required int reward,
    @Default(15) int timeLimitSec,
    @Default(<QuizQuestion>[]) List<QuizQuestion> questions,
    @Default(2) int weeklyLimit,
    @Default(0) int remainingThisWeek,
    DateTime? availableAgainAt,
  }) = _Quiz;

  factory Quiz.fromJson(Map<String, dynamic> json) => _$QuizFromJson(json);
}

/// `POST /buan/quizzes/{id}/answers` yanıtı.
@freezed
abstract class QuizAnswerResult with _$QuizAnswerResult {
  const factory QuizAnswerResult({
    required String correctOptionId,

    /// Sunucu kararı. Yoksa seçilen ile [correctOptionId] karşılaştırılır.
    bool? correct,
    String? explanation,
    @Default(0) int awarded,
  }) = _QuizAnswerResult;

  factory QuizAnswerResult.fromJson(Map<String, dynamic> json) => _$QuizAnswerResultFromJson(json);
}
