class ArabicNormalizer {
  static final RegExp _diacriticsRegex = RegExp(r'[\u064B-\u065F\u0670]');

  static String normalize(String input) {
    if (input.isEmpty) return '';

    String text = input.replaceAll(_diacriticsRegex, '');

    // Normalize Alef variants: أ, إ, آ, ٱ -> ا
    text = text.replaceAll(RegExp(r'[أإآٱ]'), 'ا');
    // Normalize Taa Marbuta: ة -> ه
    text = text.replaceAll('ة', 'ه');
    // Normalize Yaa variants: ى -> ي
    text = text.replaceAll('ى', 'ي');

    return text.trim().toLowerCase();
  }
}
