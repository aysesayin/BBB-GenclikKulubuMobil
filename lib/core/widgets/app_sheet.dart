import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Alt sayfa: r28 üst köşe, tutamaç, en fazla %90 yükseklik, kaydırılabilir içerik.
abstract final class AppSheet {
  static Future<T?> show<T>(BuildContext context, {required WidgetBuilder builder, bool scrollable = true, bool dismissible = true}) {
    final p = context.palette;
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      isDismissible: dismissible,
      enableDrag: dismissible,
      backgroundColor: p.sf,
      barrierColor: p.scrim,
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
      sheetAnimationStyle: const AnimationStyle(duration: AppDurations.sheet),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              Flexible(
                child: scrollable
                    ? SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 4, 24, 24), child: builder(ctx))
                    : Padding(padding: const EdgeInsets.fromLTRB(24, 4, 24, 24), child: builder(ctx)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 10, bottom: 10),
          width: 40,
          height: 5,
          decoration: BoxDecoration(color: context.palette.line, borderRadius: BorderRadius.circular(3)),
        ),
      );
}
