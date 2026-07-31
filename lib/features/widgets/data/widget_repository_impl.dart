import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/local_storage/hive_storage.dart';
import '../../../core/native/widget_platform.dart';
import '../domain/models/widget_config_model.dart';
import '../domain/repositories/widget_repository.dart';

class WidgetRepositoryImpl implements WidgetRepository {
  final Box<Map<dynamic, dynamic>> _box = HiveStorage.widgetsBox;

  @override
  Future<List<WidgetConfigModel>> getAllWidgets() async {
    final List<WidgetConfigModel> list = [];
    for (var key in _box.keys) {
      final map = _box.get(key);
      if (map != null) {
        final castedMap = Map<String, dynamic>.from(map);
        list.add(WidgetConfigModel.fromMap(castedMap));
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<WidgetConfigModel?> getWidgetById(String id) async {
    final map = _box.get(id);
    if (map == null) return null;
    return WidgetConfigModel.fromMap(Map<String, dynamic>.from(map));
  }

  @override
  Future<void> saveWidget(WidgetConfigModel config) async {
    final map = config.toMap();
    await _box.put(config.id, map);

    // If native widgetId exists, sync with native AppWidget
    if (config.widgetId != -1) {
      await WidgetPlatform.saveWidgetConfig(
        widgetId: config.widgetId,
        configMap: map,
      );
    }
  }

  @override
  Future<void> deleteWidget(String id) async {
    final widget = await getWidgetById(id);
    if (widget != null && widget.widgetId != -1) {
      await WidgetPlatform.deleteWidget(widget.widgetId);
    }
    await _box.delete(id);
  }

  @override
  Future<bool> pinWidgetToLauncher(WidgetConfigModel config) async {
    await saveWidget(config);
    return await WidgetPlatform.pinWidget(config.toMap());
  }

  @override
  Future<WidgetConfigModel> duplicateWidget(WidgetConfigModel config) async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final duplicated = config.copyWith(
      id: newId,
      widgetId: -1,
      contactName: '${config.contactName} (Copy)',
      createdAt: DateTime.now(),
    );
    await saveWidget(duplicated);
    return duplicated;
  }
}
