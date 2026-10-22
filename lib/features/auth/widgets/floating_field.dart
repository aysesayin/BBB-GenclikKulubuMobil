import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ui_prefs_controller.dart';

/// 62 px "floating label" alan: odakta/doluyken etiket 16 → 12 px yukarı kayar (200 ms).
/// Çerçeve: odakta turkuaz, hatada koyu kırmızı.
/// Kolay Mod: etiket kaymaz, 16 px olarak kutunun üstünde sabit durur.
class FloatingField extends StatefulWidget {
  const FloatingField({
    super.key,
    required this.label,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.inputFormatters,
    this.autofillHints,
    this.obscure = false,
    this.error = false,
    this.suffix,
    this.textInputAction,
  });

  final String label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged, onSubmitted;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final bool obscure, error;
  final Widget? suffix;
  final TextInputAction? textInputAction;

  @override
  State<FloatingField> createState() => _FloatingFieldState();
}

class _FloatingFieldState extends State<FloatingField> {
  final _focus = FocusNode();
  late final TextEditingController _ctrl = widget.controller ?? TextEditingController();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    if (widget.controller == null) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final up = _focus.hasFocus || _ctrl.text.isNotEmpty;
    final border = widget.error ? p.errorText : (_focus.hasFocus ? p.primary : p.line);
    final easy = context.easyMode;
    final box = GestureDetector(
      onTap: _focus.requestFocus,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        height: 62,
        decoration: BoxDecoration(
          color: p.sf,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: 2),
        ),
        child: Stack(
          children: [
            if (!easy)
              AnimatedPositioned(
              duration: AppDurations.fast,
              curve: const Cubic(.2, .8, .2, 1),
              left: 16,
              top: up ? 6 : 17,
              child: IgnorePointer(
                child: AnimatedDefaultTextStyle(
                  duration: AppDurations.fast,
                  style: AppTypography.body(up ? 12 : 16, weight: FontWeight.w800, color: widget.error ? p.errorText : p.mut),
                  child: ExcludeSemantics(child: Text(widget.label)),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: widget.suffix == null ? 14 : 58,
              bottom: easy ? 14 : 6,
              child: Semantics(
                label: widget.label,
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  obscureText: widget.obscure,
                  keyboardType: widget.keyboardType,
                  inputFormatters: widget.inputFormatters,
                  autofillHints: widget.autofillHints,
                  textInputAction: widget.textInputAction,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  style: AppTypography.body(18, weight: FontWeight.w800, color: p.ink),
                  cursorColor: p.teal,
                  decoration: const InputDecoration.collapsed(
                    hintText: null,
                  ).copyWith(isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 4), filled: false),
                ),
              ),
            ),
            if (widget.suffix != null) Positioned(right: 6, top: 7, child: widget.suffix!),
          ],
        ),
      ),
    );
    if (!easy) return box;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Text(widget.label, style: AppTypography.body(16, weight: FontWeight.w900, color: widget.error ? p.errorText : p.mut)),
        ),
        const SizedBox(height: 8),
        box,
      ],
    );
  }
}
