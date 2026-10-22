import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/repositories/cart_repository.dart';
import '../../../../data/services/cart_payment_launcher.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/svc_format.dart';
import '../view_model/cart_view_model.dart';
import '../widgets/cart_sections.dart';
import '../widgets/cart_totals.dart';
import '../widgets/hold_timer_card.dart';

/// H3 · Sepet (tam ekran): 5 dk rezerv sayacı, indirim/kupon, toplamlar, 3D Secure ödeme.
class CartView extends StatelessWidget {
  const CartView({super.key, @visibleForTesting this.createViewModel});

  /// Testlerde sahte repository / saat ile VM kurmak için.
  final CartViewModel Function()? createViewModel;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => (createViewModel?.call() ?? CartViewModel(sl<CartRepository>(), payment: sl<PaymentLauncher>()))..load(),
        child: const _Body(),
      );
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> with WidgetsBindingObserver {
  /// Sayaç kartı kaydırılıp ağaçtan çıksa bile süre bitişi denetlenir.
  Timer? _expiryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) context.read<CartViewModel>().checkExpiry();
    });
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) context.read<CartViewModel>().resync();
  }

  void _reselect() {
    final nav = GoRouter.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.go(Routes.pools);
    }
  }

  Future<void> _pay(CartViewModel vm) async {
    final l = context.l10n;
    final o = await vm.checkout();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (o.kind) {
      case PaymentOutcome.success:
        Haptics.medium();
        messenger.showSnackBar(SnackBar(content: Text(l.svcPaySuccess)));
        context.go(Routes.applications);
      case PaymentOutcome.pending:
        messenger.showSnackBar(SnackBar(content: Text(l.svcPayPending)));
        context.go(Routes.applications);
      case PaymentOutcome.failed:
        final e = o.error;
        messenger.showSnackBar(SnackBar(content: Text(e == null ? l.svcPayFailed : errorMessageOf(context, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CartViewModel>();
    final p = context.palette;
    final l = context.l10n;
    final hasContent = vm.state.dataOrNull != null && (vm.expired || (vm.cart?.items.isNotEmpty ?? false));
    return Scaffold(
      backgroundColor: p.bg,
      bottomNavigationBar: hasContent ? _PayBar(vm: vm, onPay: () => _pay(vm), onReselect: _reselect) : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBackHeader(title: l.svcCartTitle, titleSize: 28),
          Expanded(
            child: ViewStateBuilder<CartData>(
              state: vm.state,
              onRetry: vm.load,
              skeleton: (_) => const _CartSkeleton(),
              empty: (_) => EmptyState(
                title: l.svcCartEmptyTitle,
                message: l.svcCartEmptyMessage,
                ctaLabel: l.svcBrowsePools,
                onCta: () => context.go(Routes.pools),
              ),
              builder: (context, data, {required offline}) => ListView(
                children: [
                  if (offline) const OfflineBanner(),
                  HoldTimerCard(vm: vm),
                  for (final item in data.cart.items) CartItemCard(item: item),
                  if (!vm.expired) ...[
                    if (data.discounts.isNotEmpty) _DiscountSection(vm: vm),
                    if (data.wallet.balance > 0)
                      CouponToggleRow(wallet: data.wallet, value: vm.useCoupon, onChanged: (v) => vm.setUseCoupon(value: v)),
                    CartTotals(subtotal: vm.subtotal, discount: vm.discountAmount, coupon: vm.couponAmount, total: vm.total),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscountSection extends StatelessWidget {
  const _DiscountSection({required this.vm});

  final CartViewModel vm;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(context.l10n.svcDiscountsTitle, style: AppTypography.display(19, color: p.ink))),
          const SizedBox(height: 12),
          for (final d in vm.discounts) ...[
            DiscountOptionRow(
              discount: d,
              selected: vm.discountId == d.id,
              onTap: () => d.usable ? vm.selectDiscount(d.id) : context.push(Routes.discounts),
            ),
            const SizedBox(height: 8),
          ],
          DiscountOptionRow(discount: null, selected: vm.discountId == null, onTap: () => vm.selectDiscount(null)),
        ],
      ),
    );
  }
}

class _PayBar extends StatelessWidget {
  const _PayBar({required this.vm, required this.onPay, required this.onReselect});

  final CartViewModel vm;
  final VoidCallback onPay, onReselect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return StickyBottomBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(AppIcons.lock, size: 14, color: p.mut, strokeWidth: 2.6),
              const SizedBox(width: 6),
              Flexible(child: Text(l.svcSecurePayment, style: AppTypography.body(12, weight: FontWeight.w800, color: p.mut))),
            ],
          ),
          const SizedBox(height: 6),
          const _CardBrands(),
          const SizedBox(height: 8),
          if (vm.expired)
            AppButton(label: l.svcReselect, onPressed: onReselect)
          else
            AppButton(label: l.svcPayCta(SvcFmt.money(context, vm.total)), busy: vm.paying, onPressed: vm.canPay ? onPay : null),
        ],
      ),
    );
  }
}

/// "Sanal POS · 3D Secure" altındaki kabul edilen kart çipleri (metin; logo görseli yok).
class _CardBrands extends StatelessWidget {
  const _CardBrands();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final brands = l.svcCardBrands.split('|').where((b) => b.trim().isNotEmpty).toList();
    return Semantics(
      label: '${l.svcAcceptedCards}: ${brands.join(', ')}',
      excludeSemantics: true,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final b in brands)
            Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: p.sf2, borderRadius: BorderRadius.circular(11), border: Border.all(color: p.line)),
              child: Center(widthFactor: 1, child: Text(b.trim(), style: AppTypography.body(11, weight: FontWeight.w900, color: p.ink))),
            ),
        ],
      ),
    );
  }
}

class _CartSkeleton extends StatelessWidget {
  const _CartSkeleton();

  @override
  Widget build(BuildContext context) => const Shimmer(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            children: [
              SkeletonBox(height: 68, radius: 20),
              SizedBox(height: 14),
              SkeletonBox(height: 80, radius: 22),
              SizedBox(height: 24),
              SkeletonBox(height: 56, radius: 18),
              SizedBox(height: 8),
              SkeletonBox(height: 56, radius: 18),
              SizedBox(height: 18),
              SkeletonBox(height: 140, radius: 20),
            ],
          ),
        ),
      );
}
