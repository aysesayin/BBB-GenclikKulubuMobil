import '../../../../core/base/base_view_model.dart';
import '../../../../core/base/view_state.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/app_exception.dart';
import '../../../../data/models/profile/discount.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../view_model/picked_document.dart';

class DiscountsData {
  const DiscountsData({required this.types, required this.mine});

  final List<DiscountType> types;
  final List<UserDiscount> mine;
}

enum DiscountFormIssue { noType, noDocument, tooLarge }

/// I3 · İndirim tanımla: tanımlı indirimler + yeni başvuru (tür seç → belge → onaya gönder).
class DiscountsViewModel extends LoadableViewModel<DiscountsData> {
  DiscountsViewModel(this._repo, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final ProfileRepository _repo;
  final DateTime Function() _clock;

  DateTime get today => _clock();

  String? _typeId;
  String? get selectedTypeId => _typeId;
  DiscountType? get selectedType => state.dataOrNull?.types.where((t) => t.id == _typeId).firstOrNull;

  PickedDocument? _document;
  PickedDocument? get document => _document;

  bool _submitting = false;
  bool get submitting => _submitting;

  DiscountFormIssue? _issue;
  DiscountFormIssue? get issue => _issue;

  AppException? _error;
  AppException? get error => _error;

  @override
  Future<ApiResult<DiscountsData>> fetch() async {
    final typesFuture = _repo.discountTypes();
    final mineFuture = _repo.discounts();
    final types = await typesFuture;
    final mine = await mineFuture;
    return switch ((types, mine)) {
      (Failure(:final error), _) || (_, Failure(:final error)) => Failure(error),
      (Success(data: final t, fromCache: final c1), Success(data: final m, fromCache: final c2)) => Success(
        DiscountsData(types: t, mine: m),
        fromCache: c1 || c2,
      ),
    };
  }

  void selectType(String id) {
    _typeId = id;
    if (_issue == DiscountFormIssue.noType) _issue = null;
    notify();
  }

  /// Reddedilen / süresi dolan indirime dokununca aynı tür için yeniden başvuru.
  void renew(UserDiscount discount) => selectType(discount.typeId);

  void setDocument(PickedDocument? doc) {
    if (doc != null && doc.tooLarge) {
      _issue = DiscountFormIssue.tooLarge;
      notify();
      return;
    }
    _document = doc;
    if (_issue == DiscountFormIssue.noDocument || _issue == DiscountFormIssue.tooLarge) _issue = null;
    notify();
  }

  /// true → onaya gönderildi.
  Future<bool> submit() async {
    if (_submitting) return false;
    final typeId = _typeId;
    final doc = _document;
    _error = null;
    _issue = typeId == null ? DiscountFormIssue.noType : (doc == null ? DiscountFormIssue.noDocument : null);
    if (_issue != null || typeId == null || doc == null) {
      notify();
      return false;
    }
    _submitting = true;
    notify();
    final ok = await _send(typeId, doc);
    _submitting = false;
    if (isDisposed) return ok;
    if (ok) {
      _typeId = null;
      _document = null;
    }
    notify();
    return ok;
  }

  /// Belge yüklemesi başarısız olursa oluşturulan kayıt saklanır; tekrar denemede yeniden oluşturulmaz.
  UserDiscount? _created;

  Future<bool> _send(String typeId, PickedDocument doc) async {
    var discount = _created?.typeId == typeId ? _created : null;
    if (discount == null) {
      final created = await _repo.createDiscount(typeId, idempotencyKey: 'dsc-$typeId-${doc.sizeBytes}-${doc.name}');
      switch (created) {
        case Failure(:final error):
          _error = error;
          return false;
        case Success(:final data):
          discount = _created = data;
      }
    }
    final upload = await _repo.uploadDiscountDocument(discount.id, path: doc.path, fileName: doc.name);
    if (upload case Failure(:final error)) {
      _error = error;
      return false;
    }
    _created = null;
    final data = state.dataOrNull;
    if (data != null) {
      state = ViewSuccess(DiscountsData(types: data.types, mine: [discount, ...data.mine.where((d) => d.id != discount!.id)]));
    }
    return true;
  }
}
