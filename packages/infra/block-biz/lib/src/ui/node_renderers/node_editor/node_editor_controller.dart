import 'package:app_core/di.dart';

import '../../../domain/property.dart';
import '../../../domain/property_config.dart';
import '../../../mappers/property_mapper.dart';
import '../../../repository/property_config_repository.dart';
import '../../../repository/property_repository.dart';
import '../../../supports/property_def_registry.dart';
import '../../state/property_state.dart';

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
        .read(defaultConfigPropertyDefProvider(defId))
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
}

@riverpod
Stream<PropertyState> watchProperty(Ref ref, PropertyKey key) async* {
  final descriptor = ref
      .read(propertyDescriptorProvider(key.defId))
      .typeDescriptor;
  final repo = await ref.watch(propertyRepositoryProvider.future);
  yield* repo
      .watchSingle(key, descriptor.storageType)
      .map((p) => p.toState(descriptor.valueConverter));
}
