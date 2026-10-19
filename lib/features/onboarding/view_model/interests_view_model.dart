import '../../../core/base/base_view_model.dart';
import '../../../core/network/api_result.dart';
import '../../../data/models/auth/interest_option.dart';
import '../../../data/repositories/interests_repository.dart';

/// A4 · Baloncuk seçici: en az [minSelection] ilgi alanı seçilince Devam açılır.
/// Seçim kayıt bitene kadar repository'de bekletilir.
class InterestsViewModel extends LoadableViewModel<List<InterestOption>> {
  InterestsViewModel(this._repo) : _selected = {..._repo.held};

  final InterestsRepository _repo;

  // TODO(varsayım): En az seçim sayısı panelden gelebilir; tasarımdaki 3 kullanıldı.
  static const minSelection = 3;

  final Set<String> _selected;
  Set<String> get selected => Set.unmodifiable(_selected);
  int get count => _selected.length;
  bool get canContinue => _selected.length >= minSelection;

  /// Son seçilen baloncuk (wobble animasyonu yalnız onda oynar).
  String? _last;
  String? get lastSelected => _last;

  bool isSelected(String id) => _selected.contains(id);

  @override
  Future<ApiResult<List<InterestOption>>> fetch() => _repo.options();

  @override
  bool isEmpty(List<InterestOption> data) => data.isEmpty;

  void toggle(String id) {
    if (!_selected.remove(id)) {
      _selected.add(id);
      _last = id;
    } else if (_last == id) {
      _last = null;
    }
    notify();
  }

  /// Seçimi bekletir; görünüm kayda geçer. false → yeterli seçim yok.
  bool submit() {
    if (!canContinue) return false;
    _repo.hold(_selected);
    return true;
  }
}
