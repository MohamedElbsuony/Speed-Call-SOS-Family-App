import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/local_storage/hive_storage.dart';
import '../domain/models/contact_model.dart';
import '../domain/repositories/contacts_repository.dart';

class ContactsRepositoryImpl implements ContactsRepository {
  final Box<String> _pinnedBox = HiveStorage.pinnedContactsBox;
  final Box<String> _favoritesBox = HiveStorage.favoriteContactsBox;

  List<ContactModel>? _cachedContacts;

  @override
  Future<List<ContactModel>> getContacts({String query = '', bool forceRefresh = false}) async {
    final permissionGranted = await fc.FlutterContacts.requestPermission(readonly: true);
    if (!permissionGranted) {
      return [];
    }

    // Fast Memory Cache Hit for Zero-Latency Navigation
    if (_cachedContacts != null && !forceRefresh) {
      return _filterAndSort(_cachedContacts!, query);
    }

    try {
      // Disabled withPhoto: true to eliminate heavy ContentResolver I/O overhead (100x faster!)
      final fcContacts = await fc.FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      final List<ContactModel> result = [];

      for (var c in fcContacts) {
        if (c.phones.isEmpty) continue;

        final displayName = c.displayName.isNotEmpty ? c.displayName : 'No Name';

        final phoneEntries = c.phones.map((p) {
          final labelStr = p.label.name.isNotEmpty
              ? p.label.name[0].toUpperCase() + p.label.name.substring(1)
              : 'Mobile';
          return PhoneEntry(number: p.number, label: labelStr);
        }).toList();

        final isPinned = _pinnedBox.containsKey(c.id);
        final isFavorite = c.isStarred || _favoritesBox.containsKey(c.id);

        result.add(ContactModel(
          id: c.id,
          displayName: displayName,
          phones: phoneEntries,
          photoPath: '',
          isPinned: isPinned,
          isFavorite: isFavorite,
        ));
      }

      _cachedContacts = result;
      return _filterAndSort(result, query);
    } catch (_) {
      return [];
    }
  }

  List<ContactModel> _filterAndSort(List<ContactModel> contacts, String query) {
    final filtered = contacts.where((c) {
      if (query.isEmpty) return true;
      final q = query.toLowerCase();
      final nameMatches = c.displayName.toLowerCase().contains(q);
      final phoneMatches = c.phones.any((p) => p.number.contains(query));
      return nameMatches || phoneMatches;
    }).map((c) {
      // Dynamically update pin/favorite flags from Hive
      return c.copyWith(
        isPinned: _pinnedBox.containsKey(c.id),
        isFavorite: c.isFavorite || _favoritesBox.containsKey(c.id),
      );
    }).toList();

    filtered.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      return a.displayName.compareTo(b.displayName);
    });

    return filtered;
  }

  @override
  Future<List<ContactModel>> getFavoriteContacts() async {
    final contacts = await getContacts();
    return contacts.where((c) => c.isFavorite).toList();
  }

  @override
  Future<List<ContactModel>> getPinnedContacts() async {
    final contacts = await getContacts();
    return contacts.where((c) => c.isPinned).toList();
  }

  @override
  Future<void> togglePinContact(String contactId) async {
    if (_pinnedBox.containsKey(contactId)) {
      await _pinnedBox.delete(contactId);
    } else {
      await _pinnedBox.put(contactId, contactId);
    }

    if (_cachedContacts != null) {
      final index = _cachedContacts!.indexWhere((c) => c.id == contactId);
      if (index != -1) {
        final current = _cachedContacts![index];
        _cachedContacts![index] = current.copyWith(isPinned: !current.isPinned);
      }
    }
  }

  @override
  Future<void> toggleFavoriteContact(String contactId) async {
    if (_favoritesBox.containsKey(contactId)) {
      await _favoritesBox.delete(contactId);
    } else {
      await _favoritesBox.put(contactId, contactId);
    }

    if (_cachedContacts != null) {
      final index = _cachedContacts!.indexWhere((c) => c.id == contactId);
      if (index != -1) {
        final current = _cachedContacts![index];
        _cachedContacts![index] = current.copyWith(isFavorite: !current.isFavorite);
      }
    }
  }
}
