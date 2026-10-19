import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension OnbNavX on BuildContext {
  /// Yığında önceki ekran varsa geri, yoksa (deep link / `go`) [fallback]'e gider.
  void popOr(String fallback) => canPop() ? pop() : go(fallback);
}
