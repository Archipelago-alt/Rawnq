/// Arabic text normalisation, mirroring the normalisation the live storefront
/// applies before matching search terms.
///
/// Without this, searching `قمصان` would miss the real category `قُمْصَان`
/// because of the diacritics, and `احمر` would miss `أحمر`.
class ArabicText {
  const ArabicText._();

  /// Combining marks: tashkeel (harakat), tatweel and the superscript alef.
  static final RegExp _diacritics = RegExp(
    r'[ؐ-ًؚ-ٰٟۖ-ۭـ]',
  );

  static final RegExp _nonSearchable = RegExp(
    r'[^ء-يa-z0-9\s]',
  );

  static final RegExp _whitespace = RegExp(r'\s+');

  /// Folds an Arabic (or mixed) string into a comparable search key.
  static String normalise(String input) {
    if (input.isEmpty) return '';
    var value = input.toLowerCase();
    value = value.replaceAll(_diacritics, '');
    value = value
        .replaceAll(RegExp('[أإآٱ]'), 'ا') // أ إ آ ٱ -> ا
        .replaceAll('ة', 'ه') // ة -> ه
        .replaceAll('ى', 'ي') // ى -> ي
        .replaceAll('ؤ', 'و') // ؤ -> و
        .replaceAll('ئ', 'ي'); // ئ -> ي
    value = _convertArabicDigits(value);
    value = value.replaceAll(_nonSearchable, ' ');
    return value.replaceAll(_whitespace, ' ').trim();
  }

  /// True when [haystack] contains every whitespace-separated token of
  /// [needle], after normalising both sides.
  static bool matches(String haystack, String needle) {
    final query = normalise(needle);
    if (query.isEmpty) return true;
    final target = normalise(haystack);
    if (target.isEmpty) return false;
    for (final token in query.split(' ')) {
      if (!target.contains(token)) return false;
    }
    return true;
  }

  static String _convertArabicDigits(String value) {
    const easternZero = 0x0660;
    const extendedZero = 0x06F0;
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      if (rune >= easternZero && rune <= easternZero + 9) {
        buffer.write(rune - easternZero);
      } else if (rune >= extendedZero && rune <= extendedZero + 9) {
        buffer.write(rune - extendedZero);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }
}
