import 'package:app_core/di.dart';

import '../../../domain/property.dart';
import '../../../repository/property_config_repository.dart';
import 'property_editor_registry.dart';

part 'node_editor_controller.g.dart';

@riverpod
class NodeEditorController extends _$NodeEditorController {
  @override
  Stream<List<PropertyKey>> build(String nodeId) async* {
    // watch
    final repo = await ref.watch(propertyConfigRepoProvider.future);
    yield* repo.watchNodeKeys(nodeId);
  }

  // File: ui/node_renderers/node_editor/node_editor_controller.dart

  Future<void> createWithDefaultConfig(String defId) async {
    // 1. 获取 UI 描述符 (PropertyEditorDescriptor)
    final descriptor = ref.read(propertyEditorDescriptorProvider(defId));

    // 2. 获取该属性的默认模式规范 (EditorModeSpec)
    // 通常是 supportedModes 的第一个，例如 StaticModeSpec
    final defaultSpec = descriptor.defaultMode;

    // 3. 构造 PropertyKey
    final key = PropertyKey(nodeId: nodeId, defId: defId);

    // 4. 使用 Spec 的工厂方法生成默认的 Domain Configuration 对象
    // 这会返回 PropertyConfig.singleStatic(...) 或其他子类
    final newConfig = defaultSpec.createDefaultConfig(key);

    // 5. 调用 Repo 进行全量更新
    final configRepo = await ref.read(propertyConfigRepoProvider.future);
    await configRepo.fullUpdate(newConfig);
  }

  Future<void> deleteProperty(String defId) async {
    final configRepo = await ref.read(propertyConfigRepoProvider.future);
    await configRepo.deleteConfig(PropertyKey(nodeId: nodeId, defId: defId));
  }
}

@riverpod
class NodeEditorModeController extends _$NodeEditorModeController {
  @override
  bool build(PropertyKey key) => false;

  void toggle() {
    state = !state;
  }
}
