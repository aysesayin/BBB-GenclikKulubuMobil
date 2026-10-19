import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/support_repository.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/delete_account_section.dart';
import '../../widgets/legal_links.dart';
import '../../widgets/list_skeleton.dart';
import '../../widgets/profile_ui.dart';
import '../view_model/support_view_model.dart';
import '../widgets/support_form.dart';
import '../widgets/support_lists.dart';

/// I6 · Destek ve yasal metinler (tam ekran).
class SupportView extends StatelessWidget {
  const SupportView({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => SupportViewModel(sl<SupportRepository>(), sl<ProfileRepository>())..load(),
    child: const _Body(),
  );
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SupportViewModel>();
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBackHeader(title: context.l10n.profileSupportTitle),
          Expanded(
            child: ViewStateBuilder<SupportData>(
              state: vm.state,
              onRetry: vm.load,
              skeleton: (_) => const ProfileListSkeleton(blocks: [330, 130, 170]),
              builder: (context, data, {required offline}) => _Content(data: data, offline: offline),
            ),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.data, required this.offline});

  final SupportData data;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SupportViewModel>();
    final p = context.palette;
    final l = context.l10n;
    return ListView(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 32),
      children: [
        if (offline) const OfflineBanner(),
        const SupportForm(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CapsLabel(l.profileSupportMine),
              const SizedBox(height: 8),
              if (data.tickets.isEmpty) Text(l.profileSupportNoTickets, style: AppTypography.body(14, color: p.mut)),
              for (var i = 0; i < data.tickets.length; i++) ...[if (i > 0) const SizedBox(height: 8), TicketTile(ticket: data.tickets[i])],
            ],
          ),
        ),
        if (data.faq.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CapsLabel(l.profileFaqTitle),
                const SizedBox(height: 6),
                FaqList(items: data.faq, openIndex: vm.openFaq, onToggle: vm.toggleFaq),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CapsLabel(l.profileLegalTitle),
              const SizedBox(height: 10),
              const LegalLinksCard(),
              const SizedBox(height: 16),
              DeleteAccountSection(onRequest: vm.requestDeletion),
            ],
          ),
        ),
      ],
    );
  }
}
