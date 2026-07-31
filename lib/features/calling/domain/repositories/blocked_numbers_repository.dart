import '../models/blocked_number_model.dart';

abstract class BlockedNumbersRepository {
  Future<List<BlockedNumberModel>> getBlockedNumbers();
  Future<bool> isNumberBlocked(String phoneNumber);
  Future<void> blockNumber(BlockedNumberModel model);
  Future<void> unblockNumber(String id);
}
