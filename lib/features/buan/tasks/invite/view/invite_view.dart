import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/base/base_view.dart';
import '../../../../../core/di/locator.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/haptics.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../data/models/buan_tasks/referral.dart';
import '../../../../../data/repositories/buan_tasks_repository.dart';
import '../../../../../l10n/l10n.dart';
import '../../widgets/task_icons.dart';
import '../view_model/invite_view_model.dart';
import '../widgets/invite_parts.dart';

/// E11 · Davet Et.
class InviteView extends StatelessWidget {
  const InviteView({super.key});

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider(create: (_) => InviteViewModel(sl<ReferralRepository>())..load(), child: const _Body());
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InviteViewModel>();
    return Scaffold(
      body: ViewStateBuilder<Referral>(
        state: vm.state,
        onRetry: vm.load,
        skeleton: (_) => Shimmer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: const [
              SkeletonBox(height: 240, radius: 32),
              SizedBox(height: 18),
              Padding(padding: AppSpacing.screenPadding, child: SkeletonBox(height: 260, radius: 24)),
            ],
          ),
        ),
        builder: (context, r, {required offline}) => ListView(
          padding: EdgeInsets.only(bottom: 30 + MediaQuery.paddingOf(context).bottom),
          children: [
            InviteHero(inviterReward: r.inviterReward, inviteeReward: r.inviteeReward),
            if (offline) const OfflineBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: _CodeCard(vm: vm, referral: r),
            ),
            _Invitees(items: r.invitees),
          ],
        ),
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.vm, required this.referral});

  final InviteViewModel vm;
  final Referral referral;

  String _shareText(AppLocalizations l) => l.taskInviteShareText(Fmt.number(referral.inviteeReward), referral.code, vm.link);

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: referral.code));
    Haptics.selection();
    vm.markCopied();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.commonCopied)));
    }
  }

  Future<void> _share(BuildContext context, {bool whatsapp = false}) async {
    final l = context.l10n;
    final text = _shareText(l);
    if (whatsapp) {
      final ok = await launchUrl(
        Uri.parse('${ApiEndpoints.whatsappShare}${Uri.encodeComponent(text)}'),
        mode: LaunchMode.externalApplication,
      ).catchError((Object _) => false);
      if (ok) return;
    }
    if (!context.mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    // TODO(varsayım): Instagram metin paylaşımını desteklemez; sistem paylaşım sayfası açılır.
    await SharePlus.instance.share(
      ShareParams(text: text, subject: l.taskInviteShareSubject, sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final reset = referral.nextResetAt;
    final limitText = vm.limitReached
        ? l.taskInviteLimitUsed(referral.weeklyLimit, reset == null ? '' : DateFormat.EEEE(locale).format(reset.toLocal()))
        : l.taskInviteLimitLeft(referral.weeklyLimit, vm.remainingThisWeek);
    final share = [
      (l.taskInviteShareWhatsapp, p.tile2, TaskIcons.whatsapp, true),
      (l.taskInviteShareInstagram, p.tile1, TaskIcons.instagram, false),
      (l.taskInviteShareOther, p.tile6, TaskIcons.shareUp, false),
    ];
    return AppCard(
      radius: AppRadii.card,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.taskInviteCodeLabel,
            style: AppTypography.body(13, weight: FontWeight.w900, color: p.mut),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: DashedCodeBox(code: referral.code)),
              const SizedBox(width: 10),
              Semantics(
                button: true,
                label: l.taskInviteCopy,
                excludeSemantics: true,
                child: Material(
                  color: p.ink,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _copy(context),
                    child: SizedBox.square(
                      dimension: 56,
                      child: Center(child: AppIcon(vm.copied ? AppIcons.check : TaskIcons.copy, size: 22, color: p.sf, strokeWidth: 2.4)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(vm.link, style: AppTypography.body(13, color: p.mut)),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < share.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Material(
                    color: share[i].$2,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _share(context, whatsapp: share[i].$4),
                      child: SizedBox(
                        height: 72,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppIcon(share[i].$3, size: 24, color: p.onTile),
                            const SizedBox(height: 6),
                            Text(
                              share[i].$1,
                              style: AppTypography.body(13, weight: FontWeight.w900, color: p.onTile),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            limitText,
            style: AppTypography.body(12, weight: FontWeight.w800, color: p.mut),
          ),
        ],
      ),
    );
  }
}

class _Invitees extends StatelessWidget {
  const _Invitees({required this.items});

  final List<Invitee> items;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final avatars = [p.tile2, p.tile1, p.tile3, p.tile6, p.tile5, p.tile4];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(l.taskInviteListTitle, style: AppTypography.display(20, color: p.ink)),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(l.taskInviteEmpty, style: AppTypography.body(14, color: p.mut))
          else
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              InviteeRow(invitee: items[i], avatarColor: avatars[i % avatars.length]),
            ],
        ],
      ),
    );
  }
}
