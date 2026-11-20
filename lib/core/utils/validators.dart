class Validators {
  const Validators._();

  static final RegExp _emailRegex = RegExp(
    r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
  );

  static String? requiredField(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Normalizes Ghanaian phone numbers to international digits (`233XXXXXXXXX`).
  /// Examples:
  /// - `0550571248` -> `233550571248`
  /// - `+233 55 057 1248` -> `233550571248`
  static String normalizeGhanaPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0') && digits.length == 10) {
      return '233${digits.substring(1)}';
    }
    if (digits.length == 9) {
      return '233$digits';
    }
    return digits;
  }

  /// Validates Ghanaian Mobile Money / mobile phone numbers (MTN, Telecel, AT).
  static String? ghanaPhone(String? value, [String label = 'Phone number']) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    final normalized = normalizeGhanaPhone(value);
    if (!RegExp(r'^233[235][0-9]{8}$').hasMatch(normalized)) {
      return 'Enter a valid Ghana number (e.g. 0550571248 or +233550571248)';
    }
    return null;
  }

  static String? optionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? requiredEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    return optionalEmail(value);
  }

  static String slugify(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s\-]'), '')
        .replaceAll(RegExp(r'[\s_]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  /// Parses CSV text for admin stock & product variant imports.
  /// Expected columns (case-insensitive header):
  /// `product_slug,size,colour,stock_qty,price_override,sku`
  static List<Map<String, String>> parseCsvRows(String csvText) {
    final lines = csvText
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length < 2) return const [];

    final headers = _splitCsvLine(lines.first)
        .map((h) => h.trim().toLowerCase())
        .toList();

    final rows = <Map<String, String>>[];
    for (var i = 1; i < lines.length; i++) {
      final values = _splitCsvLine(lines[i]);
      final map = <String, String>{};
      for (var c = 0; c < headers.length; c++) {
        map[headers[c]] = c < values.length ? values[c].trim() : '';
      }
      rows.add(map);
    }
    return rows;
  }

  static List<String> _splitCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }
    result.add(buffer.toString());
    return result;
  }

  static String escapeCsvCell(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }
    return value;
  }
}
