import 'dart:math' as math;

import '../../../../data/models/services/session.dart';

enum RuleIssueKind { gender, minAge, maxAge, guardian, permission }

/// Seçimde gösterilen kural uyarısı. [blocking] → sepete eklenemez.
/// Kesin denetim sunucudadır; burada yalnız erken uyarı yapılır.
class RuleIssue {
  const RuleIssue(this.kind, {this.min = 0, this.max = 0, this.gender = Gender.unknown});

  final RuleIssueKind kind;
  final int min, max;
  final Gender gender;

  bool get blocking => switch (kind) {
        RuleIssueKind.gender || RuleIssueKind.minAge || RuleIssueKind.maxAge => true,
        RuleIssueKind.guardian || RuleIssueKind.permission => false,
      };

  @override
  bool operator ==(Object other) =>
      other is RuleIssue && other.kind == kind && other.min == min && other.max == max && other.gender == gender;

  @override
  int get hashCode => Object.hash(kind, min, max, gender);
}

/// Cinsiyet ve yaş kuralları (değerler API'den: [ItemRules.ageRules], [ItemRules.minAge]/[ItemRules.maxAge]).
List<RuleIssue> evaluateRules({required ItemRules rules, required Participant participant, required SessionSlot slot}) {
  final out = <RuleIssue>[];
  final g = slot.gender;
  if ((g == Gender.male || g == Gender.female) && participant.gender != Gender.unknown && participant.gender != g) {
    out.add(RuleIssue(RuleIssueKind.gender, gender: g));
  }
  final a = rules.ageRules;
  final minAge = math.max(rules.minAge ?? 0, a.minAge);
  final age = participant.age;
  if (age < minAge) {
    out.add(RuleIssue(RuleIssueKind.minAge, min: minAge));
  } else if (rules.maxAge != null && age > rules.maxAge!) {
    out.add(RuleIssue(RuleIssueKind.maxAge, max: rules.maxAge!));
  } else if (age <= a.guardianUntil) {
    out.add(RuleIssue(RuleIssueKind.guardian, min: a.minAge, max: a.guardianUntil));
  } else if (age <= a.permissionUntil) {
    // TODO(varsayım): Veli izin belgesi girişte kontrol edilir; uygulamadan yükleme akışı yok.
    out.add(RuleIssue(RuleIssueKind.permission, min: a.guardianUntil + 1, max: a.permissionUntil));
  }
  return out;
}
