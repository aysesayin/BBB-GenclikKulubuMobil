import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ui_prefs_controller.dart';

/// Kayıt adımlarındaki iri giriş alanı: 14/900 etiket (Kolay Mod: 16) + 60–68 px kutu (r18–20),
/// Baloo 22–28 metin. Odakta turkuaz, hatada koyu kırmızı çerçeve + mesaj.
class BigField extends StatefulWidget {
  const BigField({
    super.key,
    required this.label,
    required this.onChanged,
    this.initial = '',
    this.height = 60,
    this.radius = 18,
    this.fontSize = 22,
    this.weight = FontWeight.w700,
    this.letterSpacing,
    this.prefix,
    this.hint,
    this.error,
    this.keyboardType,
    this.inputFormatters,
    this.autofillHints,
    this.textInputAction,
    this.capitalization = TextCapitalization.none,
  });

  final String label;
  final ValueChanged<String> onChanged;
  final String initial;
  final double height, radius, fontSize;
  final FontWeight weight;
  final double? letterSpacing;
  final String? prefix, hint, error;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final TextCapitalization capitalization;

  @override
  State<BigField> createState() => _BigFieldState();
}

class _BigFieldState extends State<BigField> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.initial);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
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
    final err = widget.error;
    final border = err != null ? p.errorText : (_focus.hasFocus ? p.primary : p.line);
    final labelSize = context.easyMode ? 16.0 : 14.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: Text(widget.label, style: AppTypography.body(labelSize, weight: FontWeight.w900, color: p.mut))),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: AppDurations.fast,
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: p.sf,
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(color: border, width: 2),
          ),
          child: Row(
            children: [
              if (widget.prefix != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: p.sf2, borderRadius: BorderRadius.circular(10)),
                  child: Text(widget.prefix!, style: AppTypography.body(16, weight: FontWeight.w900, color: p.ink)),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Semantics(
                  label: widget.label,
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    keyboardType: widget.keyboardType,
                    inputFormatters: widget.inputFormatters,
                    autofillHints: widget.autofillHints,
                    textInputAction: widget.textInputAction,
                    textCapitalization: widget.capitalization,
                    onChanged: widget.onChanged,
                    cursorColor: p.teal,
                    style: AppTypography.display(widget.fontSize, weight: widget.weight, height: 1.2, color: p.ink)
                        .copyWith(letterSpacing: widget.letterSpacing),
                    decoration: InputDecoration.collapsed(
                      hintText: widget.hint,
                      hintStyle: AppTypography.display(widget.fontSize, weight: widget.weight, color: p.mut.withValues(alpha: .5)),
                    ).copyWith(filled: false),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (err != null)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(err, style: AppTypography.body(13, weight: FontWeight.w900, color: p.errorText)),
            ),
          ),
      ],
    );
  }
}

/// Telefonu yazarken "532 418 27 90" biçiminde gruplar (en çok 10 hane, baştaki 0 atılır).
class PhoneGroupFormatter extends TextInputFormatter {
  const PhoneGroupFormatter({this.leadingZero = false});

  /// true → "0532 418 27 90" (11 hane).
  final bool leadingZero;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var d = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (!leadingZero && d.startsWith('0')) d = d.substring(1);
    final max = leadingZero ? 11 : 10;
    if (d.length > max) d = d.substring(0, max);
    final cuts = leadingZero ? const {4, 7, 9} : const {3, 6, 8};
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (cuts.contains(i)) b.write(' ');
      b.write(d[i]);
    }
    final s = b.toString();
    return TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}
