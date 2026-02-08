import 'package:app_core/di.dart';

import '../domain/property.dart';
import '../domain/property_config.dart';
import '../mappers/property_mapper.dart';
import '../repository/property_config_repository.dart';
import '../repository/property_repository.dart';
import '../supports/property_def_registry.dart';
import 'state/property_state.dart';

part 'common_property_controller.g.dart';

@riverpod
Stream<PropertyConfig> propertyConfig(Ref ref, PropertyKey key) async* {
  final repo = await ref.watch(propertyConfigRepoProvider.future);
  yield* repo.watchConfig(key);
}

// self state
@riverpod
class CommonConfigController extends _$CommonConfigController {
  @override
  Future<Object> build(PropertyKey key) async {
    final descriptor = ref
        .read(propertyDescriptorProvider(key.defId))
        .typeDescriptor;

    final result = await ref.watch(propertyConfigProvider(key).future);
    return descriptor.configConverter.decode(result.configs);
  }

  Future<void> batchUpdate(List<ParticalConfigChange> changes) async {
    final repo = await ref.read(propertyConfigRepoProvider.future);
    await repo.batchUpdate(changes);
  }

  Future<void> fullUpdate<C>(C config) async {
    final repo = await ref.read(propertyConfigRepoProvider.future);
    final descriptor = ref.read(propertyDescriptorProvider(key.defId));

    await repo.fullUpdate(
      PropertyConfig(
        key: key,
        configs: descriptor.typeDescriptor.configConverter.encode(config),
      ),
    );
  }

  Future<void> particialUpdate(ParticalConfigChange change) async {
    final repo = await ref.read(propertyConfigRepoProvider.future);
    await repo.particalUpdate(change);
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
