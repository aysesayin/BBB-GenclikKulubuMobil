import 'package:flutter/material.dart';

import '../../../core/network/api_result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';

/// Sözleşme metni sayfası: metin panelden (`/app/legal/{key}`) gelir; sonuna kadar
/// kaydırılınca "Okudum, onaylıyorum" etkinleşir. true dönerse onaylandı.
abstract final class LegalSheet {
  static Future<bool> show(BuildContext context, {required String title, required Future<ApiResult<String>> Function() load}) async {
    final ok = await AppSheet.show<bool>(context, scrollable: false, builder: (_) => _LegalBody(title: title, load: load));
    return ok ?? false;
  }
}

class _LegalBody extends StatefulWidget {
  const _LegalBody({required this.title, required this.load});

  final String title;
  final Future<ApiResult<String>> Function() load;

  @override
  State<_LegalBody> createState() => _LegalBodyState();
}

class _LegalBodyState extends State<_LegalBody> {
  late Future<ApiResult<String>> _text = widget.load();
  final _scroll = ScrollController();
  bool _atEnd = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_check);
  }

  void _check() {
    if (!_scroll.hasClients) return;
    final end = _scroll.position.pixels >= _scroll.position.maxScrollExtent - 24;
    if (end != _atEnd && end) setState(() => _atEnd = true);
  }

  /// Metin kısa ve kaydırma gerekmiyorsa onay hemen açılır.
  Widget _scrollable(String data, Color color) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_atEnd && _scroll.hasClients && _scroll.position.maxScrollExtent <= 24) setState(() => _atEnd = true);
    });
    return SingleChildScrollView(
      controller: _scroll,
      child: Text(data, style: AppTypography.body(14, weight: FontWeight.w600, height: 1.6, color: color)),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(widget.title, style: AppTypography.display(24, color: p.ink))),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<ApiResult<String>>(
              future: _text,
              builder: (context, snap) {
                final r = snap.data;
                if (r == null) {
                  return const Shimmer(child: Column(children: [SkeletonBox(), SizedBox(height: 10), SkeletonBox(), SizedBox(height: 10), SkeletonBox(width: 180)]));
                }
                return switch (r) {
                  Failure(:final error) => ErrorStateView(error: error, onRetry: () async => setState(() => _text = widget.load())),
                  Success(:final data) => _scrollable(data, p.mut),
                };
              },
            ),
          ),
          const SizedBox(height: 12),
          if (!_atEnd)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(l.authLegalScrollHint, textAlign: TextAlign.center, style: AppTypography.caption.copyWith(color: p.mut)),
            ),
          AppButton(label: l.authLegalAccept, onPressed: _atEnd ? () => Navigator.of(context).pop(true) : null),
        ],
      ),
    );
  }
}
