import 'package:app_core/di.dart';

import '../../../domain/property.dart';
import '../../../domain/property_config.dart';
import '../../../repository/property_config_repository.dart';
import '../../../repository/property_repository.dart';
import '../../../supports/property_descriptor_registry.dart';

part 'node_editor_controller.g.dart';

@riverpod
class NodeEditorController extends _$NodeEditorController {
  @override
  Stream<Set<PropertyKey>> build(String nodeId) async* {
    // watch
    final repo = await ref.watch(propertyConfigRepoProvider.future);
    yield* repo.watchNodeKeys(nodeId);
  }

  Future<void> createWithDefaultConfig(String defId) async {
    final descriptor = ref.read(propertyDescriptorProvider(defId));
    final spec = descriptor.configSpecDescriptors.first;
    final newConfig = spec.createDefault();
    final configRepo = await ref.read(propertyConfigRepoProvider.future);
    await configRepo.fullUpdate(
      PropertyConfig(
        key: PropertyKey(nodeId: nodeId, defId: defId),
        spec: spec.id,
        body: newConfig,
      ),
    );
  }

  Future<void> deleteProperty(String defId) async {
    final configRepo = await ref.read(propertyConfigRepoProvider.future);
    await configRepo.deleteConfig(PropertyKey(nodeId: nodeId, defId: defId));
  }
}

@riverpod
Stream<Property?> watchProperty(Ref ref, PropertyKey key) async* {
  final descriptor = ref.watch(propertyDescriptorProvider(key.defId));
  final repo = await ref.watch(propertyRepositoryProvider.future);
  yield* repo.watchSingle(key, descriptor.dateType.definition.storageType);
}
