import 'package:app_core/di.dart';

import '../../../domain/property.dart';
import '../../../domain/property_config.dart';
import '../../../repository/property_config_repository.dart';
import '../../../supports/property_def_registry.dart';
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

  Future<void> createWithDefaultConfig(String defId) async {
    final defaultConfig = ref
        .read(editorDescriptorProvider(defId))
        .defaultConfig;
    final configRepo = await ref.read(propertyConfigRepoProvider.future);
    final descriptor = ref.read(propertyDescriptorProvider(defId));

    await configRepo.fullUpdate(
      PropertyConfig(
        key: PropertyKey(nodeId: nodeId, defId: defId),
        configs: descriptor.typeDescriptor.configConverter.encode(
          defaultConfig,
        ),
      ),
    );
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
