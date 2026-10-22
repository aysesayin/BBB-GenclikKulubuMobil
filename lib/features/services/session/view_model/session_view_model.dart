import 'dart:async';

import '../../../../core/base/base_view_model.dart';
import '../../../../core/base/view_state.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/app_exception.dart';
import '../../../../data/models/services/session.dart';
import '../../../../data/repositories/cart_repository.dart';
import '../../../../data/repositories/facility_repository.dart';
import 'session_rules.dart';

export 'session_rules.dart';

enum CellKind { open, selected, full, ineligible, cancelled, maintenance, holiday, past, empty }

/// H2 · Haftalık seans ızgarası: hafta gezinme, kimin için, seçim + kural uyarıları, 5 dk rezerv,
/// dolu seans için bekleme listesi, uygun olmayan (yaş/cinsiyet) hücreler, Kolay Mod gün gezinme.
class SessionViewModel extends LoadableViewModel<SessionWeek> {
  SessionViewModel(
    this._repo,
    this._cart, {
    required this.itemId,
    Clock? now,
    // TODO(varsayım): Canlı kontenjan için WebSocket paketi yok; 30 sn'de bir sessiz yenileme yapılır.
    Duration? pollInterval = const Duration(seconds: 30),
  })  : _now = now ?? DateTime.now,
        _pollInterval = pollInterval {
    _weekStart = mondayOf(_now());
    _focusDay = _day(_now());
  }

  final FacilityRepository _repo;
  final CartRepository _cart;
  final String itemId;
  final Clock _now;
  final Duration? _pollInterval;

  late DateTime _weekStart;
  late DateTime _focusDay;
  bool _initialLoad = true;
  String? _participantId;
  String? _selectedId;
  bool _swimConfirmed = false;
  bool _adding = false;
  bool _joiningWaitlist = false;
  AppException? _actionError;
  Timer? _poll;

  /// Bu oturumda girilen bekleme listeleri (seans id → sıra).
  /// TODO(varsayım): Sunucu seans yanıtında `waitlistPosition` döndürene kadar yalnız yerel tutulur.
  final Map<String, int> _waitlist = {};

  static DateTime mondayOf(DateTime d) => DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));
  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime get weekStart => _weekStart;
  DateTime get weekEnd => _weekStart.add(const Duration(days: 6));
  bool get canGoPrev => _weekStart.isAfter(mondayOf(_now()));
  bool get adding => _adding;
  bool get joiningWaitlist => _joiningWaitlist;
  bool get swimConfirmed => _swimConfirmed;
  bool get requiresSwim => state.dataOrNull?.rules.requiresSwimConfirmation ?? false;

  @override
  Future<ApiResult<SessionWeek>> fetch() => _repo.sessions(itemId, from: _weekStart, to: weekEnd);

  @override
  Future<void> load() async {
    await super.load();
    final week = state.dataOrNull;
    if (week == null || isDisposed) return;
    // Sunucu istenen haftayı döndürmediyse (ör. mock) ilk açılışta verinin haftasına geç.
    if (_initialLoad && days.isEmpty && week.days.isNotEmpty) {
      _weekStart = mondayOf(week.days.first.date);
      _focusDay = _day(week.days.first.date);
    }
    _initialLoad = false;
    if (!week.participants.any((p) => p.id == _participantId)) {
      _participantId = week.participants.isEmpty ? null : week.participants.first.id;
    }
    if (selectedSlot == null) _selectedId = null;
    _startPolling();
    notify();
  }

  // ---- Izgara ----
  List<SessionDay> get days {
    final end = _weekStart.add(const Duration(days: 7));
    return [
      for (final d in state.dataOrNull?.days ?? const <SessionDay>[])
        if (!_day(d.date).isBefore(_weekStart) && _day(d.date).isBefore(end)) d,
    ];
  }

  /// Satırlar: haftadaki seans başlangıçları (günün dakikası).
  List<int> get rowMinutes {
    final set = <int>{};
    final visible = days.map((d) => _day(d.date)).toSet();
    for (final s in state.dataOrNull?.slots ?? const <SessionSlot>[]) {
      if (visible.contains(_day(s.start))) set.add(s.start.hour * 60 + s.start.minute);
    }
    return set.toList()..sort();
  }

  SessionSlot? slotAt(DateTime day, int minuteOfDay) {
    for (final s in state.dataOrNull?.slots ?? const <SessionSlot>[]) {
      if (_day(s.start) == _day(day) && s.start.hour * 60 + s.start.minute == minuteOfDay) return s;
    }
    return null;
  }

  /// Bir günün seansları, saate göre sıralı (Kolay Mod tek gün görünümü).
  List<SessionSlot> slotsOn(DateTime day) =>
      [for (final s in state.dataOrNull?.slots ?? const <SessionSlot>[]) if (_day(s.start) == _day(day)) s]
        ..sort((a, b) => a.start.compareTo(b.start));

  bool isToday(DateTime d) => _day(d) == _day(_now());

  CellKind kindOf(SessionSlot? slot, SessionDay day) {
    if (day.status == DayStatus.holiday) return CellKind.holiday;
    if (slot == null) return day.status == DayStatus.maintenance ? CellKind.maintenance : CellKind.empty;
    return switch (slot.status) {
      SlotStatus.holiday => CellKind.holiday,
      SlotStatus.maintenance => CellKind.maintenance,
      SlotStatus.cancelled => CellKind.cancelled,
      _ when day.status == DayStatus.maintenance || day.status == DayStatus.closed => CellKind.maintenance,
      _ when !slot.start.isAfter(_now()) => CellKind.past,
      _ when ineligibilityOf(slot) != null => CellKind.ineligible,
      _ when slot.isFull => CellKind.full,
      _ when slot.id == _selectedId => CellKind.selected,
      _ => CellKind.open,
    };
  }

  /// Seçili katılımcı (kendim → profil yaş/cinsiyetiyle) için engelleyici kural; yoksa null.
  RuleIssue? ineligibilityOf(SessionSlot slot) {
    final week = state.dataOrNull, p = participant;
    if (week == null || p == null) return null;
    return blockingIssue(week: week, participant: p, slot: slot);
  }

  /// Bekleme listesindeki sıra (bu oturumda girildiyse).
  int? waitlistPositionOf(String slotId) => _waitlist[slotId];

  // ---- Seçim ----
  List<Participant> get participants => state.dataOrNull?.participants ?? const [];

  Participant? get participant {
    for (final p in participants) {
      if (p.id == _participantId) return p;
    }
    return null;
  }

  SessionSlot? get selectedSlot {
    for (final s in state.dataOrNull?.slots ?? const <SessionSlot>[]) {
      if (s.id == _selectedId) return s;
    }
    return null;
  }

  void selectParticipant(String id) {
    if (id == _participantId) return;
    _participantId = id;
    if (selectedSlot case final s? when ineligibilityOf(s) != null) _selectedId = null;
    notify();
  }

  void select(SessionSlot slot, SessionDay day) {
    final k = kindOf(slot, day);
    if (k != CellKind.open && k != CellKind.selected) return;
    _selectedId = slot.id;
    notify();
  }

  void setSwimConfirmed({required bool value}) {
    _swimConfirmed = value;
    notify();
  }

  List<RuleIssue> get issues {
    final week = state.dataOrNull, p = participant, s = selectedSlot;
    if (week == null || p == null || s == null) return const [];
    return evaluateRules(rules: week.rules, participant: viewerFor(week, p), slot: s);
  }

  bool get canAdd =>
      selectedSlot != null && participant != null && !_adding && !issues.any((i) => i.blocking) && (!requiresSwim || _swimConfirmed);

  // ---- Hafta / gün gezinme ----
  Future<void> nextWeek() async {
    _weekStart = _weekStart.add(const Duration(days: 7));
    _focusDay = _weekStart;
    _selectedId = null;
    await load();
  }

  Future<void> prevWeek() async {
    if (!canGoPrev) return;
    _weekStart = _weekStart.subtract(const Duration(days: 7));
    _focusDay = weekEnd;
    _selectedId = null;
    await load();
  }

  /// Kolay Mod: tek seferde gösterilen gün (haftanın içinde kalır).
  DateTime get focusDay => _focusDay.isBefore(_weekStart) || _focusDay.isAfter(weekEnd) ? _weekStart : _focusDay;

  SessionDay get focusSessionDay =>
      days.where((d) => _day(d.date) == focusDay).firstOrNull ?? SessionDay(date: focusDay, status: DayStatus.closed);

  bool get canGoPrevDay => focusDay.isAfter(_day(_now()));

  Future<void> nextDay() async {
    final n = focusDay.add(const Duration(days: 1));
    if (n.isAfter(weekEnd)) return nextWeek();
    _focusDay = n;
    _selectedId = null;
    notify();
  }

  Future<void> prevDay() async {
    if (!canGoPrevDay) return;
    final n = focusDay.subtract(const Duration(days: 1));
    if (n.isBefore(_weekStart)) return prevWeek();
    _focusDay = n;
    _selectedId = null;
    notify();
  }

  /// Tek seferlik eylem hatası (snackbar).
  AppException? takeError() {
    final e = _actionError;
    _actionError = null;
    return e;
  }

  /// POST /cart/hold → true ise sepete gidilir.
  Future<bool> addToCart() async {
    final slot = selectedSlot, p = participant;
    if (!canAdd || slot == null || p == null) return false;
    _adding = true;
    notify();
    final r = await _cart.hold(itemId: itemId, sessionId: slot.id, participantId: p.id, swimConfirmed: _swimConfirmed);
    if (isDisposed) return false;
    _adding = false;
    if (r case Failure(:final error)) {
      _actionError = error;
      notify();
      if (error is ConflictException) await _silentRefresh();
      return false;
    }
    notify();
    return true;
  }

  /// POST /services/items/{id}/waitlist → sıra numarası; başarısızsa [takeError].
  Future<int?> joinWaitlist(SessionSlot slot) async {
    if (_joiningWaitlist || !slot.isFull || ineligibilityOf(slot) != null) return null;
    _joiningWaitlist = true;
    notify();
    final r = await _repo.joinWaitlist(itemId, sessionId: slot.id);
    if (isDisposed) return null;
    _joiningWaitlist = false;
    if (r case Success(:final data)) _waitlist[slot.id] = data.position;
    if (r case Failure(:final error)) _actionError = error;
    notify();
    return r.dataOrNull?.position;
  }

  // ---- Canlı kontenjan ----
  void _startPolling() {
    final every = _pollInterval;
    if (every == null || _poll != null) return;
    _poll = Timer.periodic(every, (_) => _silentRefresh());
  }

  Future<void> _silentRefresh() async {
    if (_adding || state is! ViewSuccess<SessionWeek>) return;
    final r = await fetch();
    if (isDisposed || r is! Success<SessionWeek>) return;
    state = ViewSuccess(r.data, fromCache: r.fromCache);
    final s = selectedSlot;
    if (s == null || s.isFull || s.status != SlotStatus.open) _selectedId = null;
    notify();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }
}
