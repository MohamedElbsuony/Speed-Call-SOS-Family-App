import '../models/widget_config_model.dart';

abstract class WidgetRepository {
  Future<List<WidgetConfigModel>> getAllWidgets();
  Future<WidgetConfigModel?> getWidgetById(String id);
  Future<void> saveWidget(WidgetConfigModel config);
  Future<void> deleteWidget(String id);
  Future<bool> pinWidgetToLauncher(WidgetConfigModel config);
  Future<WidgetConfigModel> duplicateWidget(WidgetConfigModel config);
}
