import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Etiketli giriş alanı: üstte 13/800 etiket, 52 px alan, r16, 2 px çerçeve
/// (odakta turkuaz, hatada koyu pembe + altta mesaj).
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.obscure = false,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.textInputAction,
    this.suffix,
    this.maxLines = 1,
    this.enabled = true,
    this.focusNode,
    this.letterSpacing,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint, errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscure, enabled;
  final ValueChanged<String>? onChanged, onSubmitted;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final Widget? suffix;
  final int maxLines;
  final FocusNode? focusNode;
  final double? letterSpacing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTypography.body(13, weight: FontWeight.w800, color: p.ink)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          obscureText: obscure,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          maxLines: obscure ? 1 : maxLines,
          style: AppTypography.body(17, color: p.ink).copyWith(letterSpacing: letterSpacing),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            suffixIcon: suffix,
            constraints: maxLines == 1 ? const BoxConstraints(minHeight: 52) : null,
          ),
        ),
      ],
    );
  }
}
