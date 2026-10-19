import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../network/app_exception.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';
import 'app_icon.dart';
import 'app_icons.dart';
import 'blob.dart';
import 'mascot.dart';

/// S4 · Boş durum: blob + uykulu maskot + başlık + tek CTA.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.message, this.ctaLabel, this.onCta, this.mood = MascotMood.sleepy});

  final String title, message;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final MascotMood mood;

  @override
  Widget build(BuildContext context) => _MascotMessage(
        mood: mood,
        motion: MascotMotion.float,
        title: title,
        message: message,
        actions: [if (ctaLabel != null && onCta != null) AppButton(label: ctaLabel!, onPressed: onCta)],
      );
}

/// S3 · Hata / çevrimdışı: şaşkın maskot + "Tekrar dene" (+ opsiyonel ikincil aksiyon).
class ErrorStateView extends StatefulWidget {
  const ErrorStateView({super.key, required this.error, required this.onRetry, this.secondaryLabel, this.onSecondary});

  final AppException error;
  final Future<void> Function() onRetry;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  State<ErrorStateView> createState() => _ErrorStateViewState();
}

class _ErrorStateViewState extends State<ErrorStateView> {
  bool _busy = false;

  Future<void> _retry() async {
    setState(() => _busy = true);
    await widget.onRetry();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final offline = widget.error is NetworkException;
    return _MascotMessage(
      mood: MascotMood.surprised,
      motion: MascotMotion.wobble,
      title: offline ? l.offlineTitle : l.errorTitle,
      message: offline ? l.offlineMessage : errorMessageOf(context, widget.error),
      actions: [
        AppButton(label: _busy ? l.commonRetrying : l.commonRetry, busy: _busy, onPressed: _busy ? null : _retry),
        if (widget.secondaryLabel != null && widget.onSecondary != null) ...[
          const SizedBox(height: 8),
          AppButton(
            label: widget.secondaryLabel!,
            onPressed: widget.onSecondary,
            variant: AppButtonVariant.outlineInk,
            size: AppButtonSize.medium,
          ),
        ],
      ],
    );
  }
}

/// Hata tipine göre yerelleştirilmiş kısa mesaj (snackbar / satır içi).
String errorMessageOf(BuildContext context, AppException e) {
  final l = context.l10n;
  if (e.serverMessage case final m? when m.isNotEmpty) return m;
  return switch (e) {
    NetworkException() => l.offlineMessage,
    MaintenanceException() => l.errorMaintenance,
    NotFoundException() => l.errorNotFound,
    ConflictException() => l.errorConflict,
    ForbiddenException() => l.errorForbidden,
    RateLimitException() => l.errorRateLimit,
    _ => l.errorMessage,
  };
}

class _MascotMessage extends StatelessWidget {
  const _MascotMessage({required this.mood, required this.motion, required this.title, required this.message, required this.actions});

  final MascotMood mood;
  final MascotMotion motion;
  final String title, message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight.isFinite ? c.maxHeight : 0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 230,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Blob(shape: BlobShape.f, color: p.blob, width: 280),
                      Mascot(mood: mood, motion: motion, size: 180),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  header: true,
                  child: Text(title, textAlign: TextAlign.center, style: AppTypography.display(28, height: 1.05, color: p.ink)),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(message, textAlign: TextAlign.center, style: AppTypography.body(15, color: p.mut, height: 1.4)),
                ),
                const SizedBox(height: 32),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Çevrimdışısın · kayıtlı içerik gösteriliyor" üst şeridi.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 0)});

  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: margin,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: p.pinkS, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            AppIcon(AppIcons.wifiOff, size: 18, color: p.pinkT, strokeWidth: 2.6),
            const SizedBox(width: 10),
            Expanded(child: Text(context.l10n.offlineBanner, style: AppTypography.body(13, weight: FontWeight.w900, color: p.pinkT))),
          ],
        ),
      ),
    );
  }
}
