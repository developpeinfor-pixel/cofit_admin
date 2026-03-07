class HomeValidators {
  static bool isDateLabel(String label) => label.toLowerCase().contains('date');

  static String _stripQueryAndFragment(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    final q = trimmed.indexOf('?');
    final h = trimmed.indexOf('#');
    var end = trimmed.length;
    if (q >= 0 && q < end) end = q;
    if (h >= 0 && h < end) end = h;
    return trimmed.substring(0, end).toLowerCase();
  }

  static bool _hasAllowedExtension(String value, List<String> extensions) {
    final path = _stripQueryAndFragment(value);
    if (path.isEmpty) return false;
    return extensions.any((ext) => path.endsWith(ext));
  }

  static bool validImage(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return true;
    return _hasAllowedExtension(trimmed, const ['.jpg', '.jpeg', '.png']);
  }

  static bool validMp4(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    return _hasAllowedExtension(trimmed, const ['.mp4']);
  }

  static bool hasAtLeastTwoColors(String value) {
    final colors = <String>[];
    final current = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final ch = value[i];
      if (ch == ';' || ch == ',') {
        final color = current.toString().trim();
        if (color.isNotEmpty) colors.add(color);
        current.clear();
      } else {
        current.write(ch);
      }
    }
    final last = current.toString().trim();
    if (last.isNotEmpty) colors.add(last);
    return colors.length >= 2;
  }
}
