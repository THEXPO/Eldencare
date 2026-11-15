class StringUtils {
  static String normalize(String value) {
    return value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
