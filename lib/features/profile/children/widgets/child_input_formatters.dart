import 'package:flutter/services.dart';

/// Rakamları gruplara ayırır: [3,3,3,2] → "123 456 780 12" (TCKN).
class GroupedDigitsFormatter extends TextInputFormatter {
  const GroupedDigitsFormatter(this.groups, {this.separator = ' '});

  final List<int> groups;
  final String separator;

  int get maxDigits => groups.fold(0, (a, b) => a + b);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > maxDigits) digits = digits.substring(0, maxDigits);
    final b = StringBuffer();
    var i = 0;
    for (final g in groups) {
      if (i >= digits.length) break;
      if (i > 0) b.write(separator);
      final end = (i + g).clamp(0, digits.length);
      b.write(digits.substring(i, end));
      i = end;
    }
    final text = b.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// "GG.AA.YYYY" maskesi.
class DateDotsFormatter extends GroupedDigitsFormatter {
  const DateDotsFormatter() : super(const [2, 2, 4], separator: '.');
}
