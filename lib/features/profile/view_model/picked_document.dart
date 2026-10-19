/// Kullanıcının seçtiği yerel dosya (indirim belgesi, destek eki).
/// Görünüm image_picker ile seçer; ViewModel yalnız bu değeri tutar.
class PickedDocument {
  const PickedDocument({required this.path, required this.name, required this.sizeBytes});

  final String path, name;
  final int sizeBytes;

  /// Tasarım: "en fazla 5 MB".
  static const maxBytes = 5 * 1024 * 1024;

  bool get tooLarge => sizeBytes > maxBytes;
}
