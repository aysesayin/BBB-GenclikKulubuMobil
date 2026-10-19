import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

enum DigitBoxesState { normal, valid, invalid }

/// Haneli giriş (TCKN 11, OTP 6): görünür kutular + üstünde görünmez TextField
/// (klavye, yapıştırma, SMS autofill bu alana gelir).
class DigitBoxes extends StatefulWidget {
  const DigitBoxes({
    super.key,
    required this.length,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.state = DigitBoxesState.normal,
    this.height = 52,
    this.radius = 12,
    this.border = 2,
    this.gap = 4,
    this.fontSize = 24,
    this.autofillHints,
    this.autofocus = false,
    this.validFill = false,
  });

  final int length;
  final String value;
  final ValueChanged<String> onChanged;
  final String semanticLabel;
  final DigitBoxesState state;
  final double height, radius, border, gap, fontSize;
  final Iterable<String>? autofillHints;
  final bool autofocus;

  /// Doğruyken kutular yeşil zemin alır (OTP).
  final bool validFill;

  @override
  State<DigitBoxes> createState() => _DigitBoxesState();
}

class _DigitBoxesState extends State<DigitBoxes> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.value);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(DigitBoxes old) {
    super.didUpdateWidget(old);
    if (widget.value != _ctrl.text) {
      _ctrl.value = TextEditingValue(text: widget.value, selection: TextSelection.collapsed(offset: widget.value.length));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final v = widget.value;
    Color borderAt(int i) => switch (widget.state) {
          DigitBoxesState.invalid => p.errorText,
          DigitBoxesState.valid => p.successText,
          DigitBoxesState.normal => (i == v.length && _focus.hasFocus) ? p.primary : p.line,
        };
    return Stack(
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              for (var i = 0; i < widget.length; i++) ...[
                if (i > 0) SizedBox(width: widget.gap),
                Expanded(
                  child: AnimatedContainer(
                    duration: AppDurations.chip,
                    height: widget.height,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.validFill && widget.state == DigitBoxesState.valid ? p.successSoft : p.sf,
                      borderRadius: BorderRadius.circular(widget.radius),
                      border: Border.all(color: borderAt(i), width: widget.border),
                    ),
                    child: Text(i < v.length ? v[i] : '', style: AppTypography.display(widget.fontSize, height: 1, color: p.ink)),
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: Semantics(
              label: widget.semanticLabel,
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                autofocus: widget.autofocus,
                keyboardType: TextInputType.number,
                autofillHints: widget.autofillHints,
                showCursor: false,
                enableInteractiveSelection: false,
                maxLength: widget.length,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(widget.length)],
                onChanged: widget.onChanged,
                decoration: const InputDecoration(counterText: '', border: InputBorder.none, filled: false),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
