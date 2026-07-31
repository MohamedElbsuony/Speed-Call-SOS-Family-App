import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/local_storage/hive_storage.dart';
import '../domain/models/blocked_number_model.dart';
import '../domain/repositories/blocked_numbers_repository.dart';

class BlockedNumbersRepositoryImpl implements BlockedNumbersRepository {
  final Box<Map<dynamic, dynamic>> _box = HiveStorage.blockedNumbersBox;

  @override
  Future<List<BlockedNumberModel>> getBlockedNumbers() async {
    final List<BlockedNumberModel> list = [];
    for (var key in _box.keys) {
      final item = _box.get(key);
      if (item != null) {
        final castedMap = Map<String, dynamic>.from(item);
        list.add(BlockedNumberModel.fromMap(castedMap));
      }
    }
    list.sort((a, b) => b.blockedAt.compareTo(a.blockedAt));
    return list;
  }

  @override
  Future<bool> isNumberBlocked(String phoneNumber) async {
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    for (var key in _box.keys) {
      final item = _box.get(key);
      if (item != null) {
        final number = item['phoneNumber'] as String? ?? '';
        final cleanBlocked = number.replaceAll(RegExp(r'[^0-9+]'), '');
        if (cleanBlocked.isNotEmpty && clean.contains(cleanBlocked)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Future<void> blockNumber(BlockedNumberModel model) async {
    await _box.put(model.id, model.toMap());
  }

  @override
  Future<void> unblockNumber(String id) async {
    await _box.delete(id);
  }
}
