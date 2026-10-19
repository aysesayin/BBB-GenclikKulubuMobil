import '../../../../core/base/base_view_model.dart';
import '../../../../core/base/view_state.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/app_exception.dart';
import '../../../../data/models/profile/support.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/support_repository.dart';
import '../../view_model/picked_document.dart';

class SupportData {
  const SupportData({required this.tickets, required this.faq});

  final List<SupportTicket> tickets;
  final List<FaqItem> faq;
}

/// Form konuları (API'ye `name` olarak gider).
// TODO(varsayım): Konu listesi tasarımdaki 4 seçenek; panelden yönetilecekse `/support/topics` ucu gerekir.
enum SupportTopic { facilities, opportunities, buan, appBug }

enum SupportFormIssue { messageShort, tooLarge }

/// I6 · Destek: öneri / şikâyet / talep formu, taleplerim, SSS, KVKK silme talebi.
/// SSS alınamazsa ekran yine açılır (bölüm boş); taleplerim zorunludur.
class SupportViewModel extends LoadableViewModel<SupportData> {
  SupportViewModel(this._support, this._profile);

  final SupportRepository _support;
  final ProfileRepository _profile;

  static const minMessageLength = 10;

  SupportType _type = SupportType.oneri;
  SupportType get type => _type;

  SupportTopic _topic = SupportTopic.facilities;
  SupportTopic get topic => _topic;

  PickedDocument? _attachment;
  PickedDocument? get attachment => _attachment;

  bool _sending = false;
  bool get sending => _sending;

  SupportFormIssue? _issue;
  SupportFormIssue? get issue => _issue;

  AppException? _error;
  AppException? get error => _error;

  /// Açık SSS satırı (tasarımda ilki açık); -1 → hepsi kapalı.
  int _openFaq = 0;
  int get openFaq => _openFaq;

  @override
  Future<ApiResult<SupportData>> fetch() async {
    final ticketsFuture = _support.tickets();
    final faqFuture = _support.faq();
    final tickets = await ticketsFuture;
    final faq = await faqFuture;
    return switch (tickets) {
      Failure(:final error) => Failure(error),
      Success(:final data, :final fromCache) => Success(
        SupportData(tickets: data, faq: faq.dataOrNull ?? const []),
        fromCache: fromCache,
      ),
    };
  }

  void setType(SupportType value) {
    _type = value;
    notify();
  }

  void setTopic(SupportTopic value) {
    _topic = value;
    notify();
  }

  void setAttachment(PickedDocument? doc) {
    if (doc != null && doc.tooLarge) {
      _issue = SupportFormIssue.tooLarge;
      notify();
      return;
    }
    _attachment = doc;
    if (_issue == SupportFormIssue.tooLarge) _issue = null;
    notify();
  }

  void toggleFaq(int index) {
    _openFaq = _openFaq == index ? -1 : index;
    notify();
  }

  void clearIssue() {
    if (_issue == null && _error == null) return;
    _issue = null;
    _error = null;
    notify();
  }

  /// Başarılıysa oluşan talep döner ve "Taleplerim" başına eklenir.
  Future<SupportTicket?> submit(String message) async {
    if (_sending) return null;
    final text = message.trim();
    _error = null;
    _issue = text.length < minMessageLength ? SupportFormIssue.messageShort : null;
    if (_issue != null) {
      notify();
      return null;
    }
    _sending = true;
    notify();
    final att = _attachment;
    final result = await _support.submit(
      type: _type,
      topic: _topic.name,
      message: text,
      attachmentPath: att?.path,
      attachmentName: att?.name,
    );
    _sending = false;
    if (isDisposed) return null;
    switch (result) {
      case Success(:final data):
        _attachment = null;
        final current = state.dataOrNull;
        if (current != null) {
          state = ViewSuccess(SupportData(tickets: [data, ...current.tickets.where((t) => t.id != data.id)], faq: current.faq));
        } else {
          notify();
        }
        return data;
      case Failure(:final error):
        _error = error;
        notify();
        return null;
    }
  }

  /// KVKK hesap silme talebi. null → başarı.
  Future<AppException?> requestDeletion() async => switch (await _profile.requestDeletion()) {
    Success() => null,
    Failure(:final error) => error,
  };
}
