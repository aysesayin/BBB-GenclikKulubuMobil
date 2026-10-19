import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/network/app_exception.dart';
import '../../../../core/storage/cache_store.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/profile/account_settings.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/delete_account_section.dart';
import '../../widgets/list_skeleton.dart';
import '../../widgets/profile_ui.dart';
import '../../widgets/theme_mode_selector.dart';
import '../view_model/biometric_login.dart';
import '../view_model/settings_view_model.dart';
import '../widgets/contact_change_sheet.dart';
import '../widgets/password_change_sheet.dart';
import '../widgets/settings_rows.dart';

/// I2 · Hesap ayarları (tam ekran).
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => SettingsViewModel(sl<ProfileRepository>(), LocalBiometricLogin(sl<CacheStore>()))..load(),
    child: const _Body(),
  );
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBackHeader(title: context.l10n.profileSettingsTitle),
          Expanded(
            child: ViewStateBuilder<SettingsData>(
              state: vm.state,
              onRetry: vm.load,
              skeleton: (_) => const ProfileListSkeleton(),
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

  final SettingsData data;
  final bool offline;

  void _report(BuildContext context, AppException? error) {
    if (error != null) showProfileSnack(context, errorMessageOf(context, error));
  }

  Future<void> _changeContact(BuildContext context, ContactKind kind) async {
    final vm = context.read<SettingsViewModel>();
    final l = context.l10n;
    if (!await showContactChangeSheet(context, kind) || !context.mounted) return;
    showProfileSnack(context, l.profileContactUpdated);
    await vm.refreshUser();
  }

  Future<void> _changePassword(BuildContext context) async {
    final vm = context.read<SettingsViewModel>();
    final l = context.l10n;
    if (!await showPasswordChangeSheet(context) || !context.mounted) return;
    showProfileSnack(context, l.profilePasswordUpdated);
    await vm.refreshUser();
  }

  Future<void> _toggleBiometric(BuildContext context, bool on) async {
    final vm = context.read<SettingsViewModel>();
    final l = context.l10n;
    final result = await vm.toggleBiometric(on: on, reason: l.profileBiometricReason);
    if (!context.mounted) return;
    if (result == BiometricToggleResult.failed) showProfileSnack(context, l.profileBiometricFailed);
    if (result == BiometricToggleResult.unavailable) showProfileSnack(context, l.profileBiometricUnavailable);
  }

  String _passwordSubtitle(AppLocalizations l) {
    final at = data.user.passwordChangedAt?.toLocal();
    if (at == null) return l.profilePasswordNeverChanged;
    final now = DateTime.now();
    var months = (now.year - at.year) * 12 + now.month - at.month;
    if (now.day < at.day) months--;
    return l.profilePasswordChangedMonths(months < 0 ? 0 : months);
  }

  String _biometricTitle(AppLocalizations l, BiometricKind? kind) => switch (kind) {
    BiometricKind.face => l.profileBiometricFace,
    BiometricKind.fingerprint => l.profileBiometricFingerprint,
    _ => l.profileBiometricGeneric,
  };

  @override
  Widget build(BuildContext context) {
    final vm = context.read<SettingsViewModel>();
    final p = context.palette;
    final l = context.l10n;
    final prefs = data.prefs;
    final bioOn = context.select<SettingsViewModel, bool>((v) => v.biometricEnabled);
    final bioKind = context.select<SettingsViewModel, BiometricKind?>((v) => v.biometricKind);

    Widget toggle(String title, String sub, bool value, NotificationPrefs Function(NotificationPrefs, bool) apply) => SettingsSwitchRow(
      title: title,
      subtitle: sub,
      value: value,
      onChanged: (v) => vm.updatePrefs((pr) => apply(pr, v)).then((e) {
        if (context.mounted) _report(context, e);
      }),
    );

    return ListView(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 32),
      children: [
        if (offline) const OfflineBanner(),
        CapsLabel(l.profileSectionContact, padding: const EdgeInsets.fromLTRB(24, 18, 24, 8)),
        DividedCard(
          children: [
            SettingsActionRow(
              title: l.profilePhone,
              value: data.user.phoneMasked,
              action: l.profileChange,
              onTap: () => _changeContact(context, ContactKind.phone),
            ),
            SettingsActionRow(
              title: l.profileEmail,
              value: data.user.emailMasked,
              action: l.profileChange,
              onTap: () => _changeContact(context, ContactKind.email),
            ),
            SettingsActionRow(
              title: l.profilePassword,
              value: _passwordSubtitle(l),
              action: l.profileUpdate,
              onTap: () => _changePassword(context),
            ),
            SettingsSwitchRow(
              title: _biometricTitle(l, bioKind),
              subtitle: bioKind == null ? l.profileBiometricUnavailable : null,
              value: bioOn,
              onChanged: bioKind == null ? null : (v) => _toggleBiometric(context, v),
            ),
          ],
        ),
        CapsLabel(l.profileSectionNotifications, padding: const EdgeInsets.fromLTRB(24, 22, 24, 8)),
        DividedCard(
          children: [
            toggle(
              l.profileNotifOpportunities,
              l.profileNotifOpportunitiesSub,
              prefs.opportunities,
              (pr, v) => pr.copyWith(opportunities: v),
            ),
            toggle(l.profileNotifEvents, l.profileNotifEventsSub, prefs.events, (pr, v) => pr.copyWith(events: v)),
            toggle(l.profileNotifStreak, l.profileNotifStreakSub, prefs.streakReminder, (pr, v) => pr.copyWith(streakReminder: v)),
            toggle(
              l.profileNotifAnnouncements,
              l.profileNotifAnnouncementsSub,
              prefs.announcements,
              (pr, v) => pr.copyWith(announcements: v),
            ),
            toggle(l.profileNotifAchievements, l.profileNotifAchievementsSub, prefs.achievements, (pr, v) => pr.copyWith(achievements: v)),
          ],
        ),
        CapsLabel(l.profileSectionAppearance, padding: const EdgeInsets.fromLTRB(24, 22, 24, 8)),
        Container(
          margin: AppSpacing.screenPadding,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(AppRadii.lg)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ThemeModeSelector(),
              const SizedBox(height: 14),
              LabeledSegment(
                label: l.profileLanguage,
                child: SegmentedTabs(
                  labels: [l.profileLanguageTr, l.profileLanguageEn],
                  index: prefs.language == 'en' ? 1 : 0,
                  onChanged: (i) => vm.setLanguage(i == 1 ? 'en' : 'tr').then((e) {
                    if (context.mounted) _report(context, e);
                  }),
                ),
              ),
              const SizedBox(height: 14),
              Text(l.profileTextSizeNote, style: AppTypography.body(12, color: p.mut)),
            ],
          ),
        ),
        CapsLabel(l.profileSectionAccount, padding: const EdgeInsets.fromLTRB(24, 22, 24, 8)),
        Padding(
          padding: AppSpacing.screenPadding,
          child: DeleteAccountSection(onRequest: vm.requestDeletion),
        ),
      ],
    );
  }
}
