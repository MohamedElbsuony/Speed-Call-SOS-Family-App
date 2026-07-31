import '../models/call_log_model.dart';

abstract class CallingRepository {
  Future<bool> makeCall({
    required String phoneNumber,
    required String contactName,
    int simSelectionMode = 0,
    int? subscriptionId,
  });
  Future<List<CallLogModel>> getCallHistory();
  Future<void> clearCallHistory();
}
