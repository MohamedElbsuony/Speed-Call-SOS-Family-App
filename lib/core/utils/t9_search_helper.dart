import '../../features/contacts/domain/models/contact_model.dart';

class T9SearchHelper {
  static const Map<String, String> _charToDigitMap = {
    'a': '2', 'b': '2', 'c': '2',
    'd': '3', 'e': '3', 'f': '3',
    'g': '4', 'h': '4', 'i': '4',
    'j': '5', 'k': '5', 'l': '5',
    'm': '6', 'n': '6', 'o': '6',
    'p': '7', 'q': '7', 'r': '7', 's': '7',
    't': '8', 'u': '8', 'v': '8',
    'w': '9', 'x': '9', 'y': '9', 'z': '9',
  };

  /// Converts a contact name into digits sequence (e.g., "Mom" -> "666")
  static String nameToT9Digits(String name) {
    final buffer = StringBuffer();
    final lower = name.toLowerCase();
    for (int i = 0; i < lower.length; i++) {
      final char = lower[i];
      if (_charToDigitMap.containsKey(char)) {
        buffer.write(_charToDigitMap[char]);
      }
    }
    return buffer.toString();
  }

  /// Filters contacts list by entered T9 digit sequence
  static List<ContactModel> filterContactsByT9(List<ContactModel> contacts, String queryDigits) {
    if (queryDigits.isEmpty) return [];

    final cleanQuery = queryDigits.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanQuery.isEmpty) return [];

    return contacts.where((contact) {
      // 1. Direct phone number match
      final phoneMatch = contact.phones.any((p) =>
          p.number.replaceAll(RegExp(r'[^0-9]'), '').contains(cleanQuery));
      if (phoneMatch) return true;

      // 2. T9 Name match
      final nameT9 = nameToT9Digits(contact.displayName);
      if (nameT9.contains(cleanQuery)) return true;

      // 3. Name word start match (e.g. "John Doe" -> "John" & "Doe")
      final parts = contact.displayName.split(' ');
      for (var part in parts) {
        if (nameToT9Digits(part).startsWith(cleanQuery)) {
          return true;
        }
      }

      return false;
    }).toList();
  }
}
