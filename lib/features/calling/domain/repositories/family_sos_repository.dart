import '../models/family_sos_config_model.dart';

abstract class FamilySosRepository {
  Future<FamilySosConfigModel> getFamilySosConfig();
  Future<void> saveFamilySosConfig(FamilySosConfigModel config);
  Future<bool> pinSosWidgetToHomeScreen();
  Future<void> dispatchEmergencyAlert(FamilySosConfigModel config);
}
