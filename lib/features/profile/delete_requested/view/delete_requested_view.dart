import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/session/session_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/ui_prefs_controller.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/profile/delete_request.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/profile_icons.dart';
import '../../widgets/profile_ui.dart';

/// I2b · KVKK silme talebi alındı: sakin tam ekran (uykulu maskot), talep no + 30 günlük süreç,
/// e-posta notu ve tek "Çıkış yap" butonu. [receipt] rota `extra`sından gelir; null ise genel metin.
class DeleteRequestedView extends StatelessWidget {
  const DeleteRequestedView({super.key, this.receipt});

  final DeleteRequestReceipt? receipt;

  Future<void> _signOut(BuildContext context) async {
    final session = context.read<SessionController>();
    final router = GoRouter.of(context);
    await session.signOut();
    router.go(Routes.welcome);
  }

  String _body(BuildContext context) {
    final l = context.l10n;
    final r = receipt ?? const DeleteRequestReceipt();
    final no = r.requestNo.isNotEmpty ? r.requestNo : r.requestId;
    final until = r.processUntil;
    if (until == null) return l.profileDeleteRequestedBodyShort(no);
    return l.profileDeleteRequestedBody(no, ProfileFmt.dayMonthYear(until, Localizations.localeOf(context).languageCode));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final easy = context.easyMode;
    // TODO(varsayım): Backend `emailSent` göndermezse bilgilendirme e-postasının gittiği varsayılır.
    final emailSent = receipt?.emailSent ?? true;
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      if (easy)
                        const Mascot(mood: MascotMood.sleepy, size: 140)
                      else
                        SizedBox(
                          height: 220,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Blob(shape: BlobShape.f, color: p.blob, width: 260),
                              const Mascot(mood: MascotMood.sleepy, size: 170),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      Semantics(
                        header: true,
                        child: Text(
                          l.profileDeleteRequestedTitle,
                          textAlign: TextAlign.center,
                          style: AppTypography.display(easy ? 32 : 28, height: 1.05, color: p.ink),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _body(context),
                        textAlign: TextAlign.center,
                        style: AppTypography.body(easy ? 17 : 15, color: p.mut, height: 1.45),
                      ),
                      if (emailSent) ...[const SizedBox(height: 16), _EmailNote(text: l.profileDeleteRequestedEmail)],
                      const SizedBox(height: 10),
                      Text(
                        l.profileDeleteRequestedNote,
                        textAlign: TextAlign.center,
                        style: AppTypography.body(13, weight: FontWeight.w700, color: p.mut),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppButton(label: l.profileMenuLogout, onPressed: () => _signOut(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmailNote extends StatelessWidget {
  const _EmailNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(AppRadii.lg)),
      child: Row(
        children: [
          AppIcon(ProfileIcons.mail, size: 20, color: p.teal, strokeWidth: 2.2),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body(14, weight: FontWeight.w800, color: p.ink, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
