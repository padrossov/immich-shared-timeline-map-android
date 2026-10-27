import 'dart:convert';

/// The store value contains independent selections for each server, account
/// and view. Selecting all stores the currently listed IDs, not future albums.
class SharedAlbumPreferences {
  static String key(String server, String user, String view) => jsonEncode([server, user, view]);

  static Map<String, dynamic> _decode(String? value) {
    if (value == null) {
      return {};
    }
    try {
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : {};
    } on FormatException {
      return {};
    }
  }

  static Set<String> read(String? value, String key) {
    final ids = _decode(value)[key];
    return Set.unmodifiable(ids is List ? ids.whereType<String>() : <String>[]);
  }

  static String write(String? value, String key, Set<String> ids) =>
      jsonEncode({..._decode(value), key: ids.toList()..sort()});
}
