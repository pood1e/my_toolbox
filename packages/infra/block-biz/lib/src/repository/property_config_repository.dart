import 'package:app_core/di.dart';
import 'package:app_core/object.dart';

import '../data/daos/complex_compute_dao.dart';
import '../data/daos/property_atom_config_dao.dart';
import '../data/daos/property_dao.dart';
import '../domain/property.dart';
import '../domain/property_config.dart';
import '../domain/stored_config.dart';
import '../supports/config_spec_registry.dart';
import 'impl/property_config_repo_impl.dart';

part 'property_config_repository.freezed.dart';
part 'property_config_repository.g.dart';

/// PropertyAtomConfigChange

@freezed
abstract class ParticialUpdateConfigKey with _$ParticialUpdateConfigKey {
  const factory ParticialUpdateConfigKey({
    required String nodeId,
    required String refId,
    required ConfigType configType,
    String? mapKey,
  }) = _ParticialUpdateConfigKey;
}

@freezed
abstract class ParticalUpdateConfigRecord with _$ParticalUpdateConfigRecord {
  const factory ParticalUpdateConfigRecord({
    String? targetNodeId,
    String? targetDefId,
    String? config,
    required bool affectValue,
  }) = _ParticalUpdateConfigRecord;
}

@freezed
sealed class ParticalConfigChange with _$ParticalConfigChange {
  const factory ParticalConfigChange.insert(
    ParticialUpdateConfigKey key,
    ParticalUpdateConfigRecord record,
  ) = ParticalConfigInsert;

  const factory ParticalConfigChange.update(
    ParticialUpdateConfigKey key,
    ParticalUpdateConfigRecord record,
  ) = ParticalConfigUpdate;

  const factory ParticalConfigChange.delete(ParticialUpdateConfigKey key) =
      ParticalConfigDelete;
}

/// 职责: trx , entity -> domain
abstract class PropertyConfigRepository {
  // 全量更新
  Future<void> fullUpdate(PropertyConfig config);

  Future<void> batchUpdate(List<ParticalConfigChange> changes);

  Future<void> particalUpdate(ParticalConfigChange change) =>
      batchUpdate([change]);

  // 给ui使用
  Stream<PropertyConfig?> watchConfig(PropertyKey key);

  Future<PropertyConfig?> getConfig(PropertyKey key);

  Stream<Set<PropertyKey>> watchNodeKeys(String nodeId);

  Future<void> deleteConfig(PropertyKey key);
}

@riverpod
Future<PropertyConfigRepository> propertyConfigRepo(Ref ref) async {
  final dao = await ref.watch(propertyAtomConfigDaoProvider.future);
  final computeDao = await ref.watch(complexComputeDaoProvider.future);
  final propertyDao = await ref.watch(propertyDaoProvider.future);
  final descriptorMap = ref.read(configSpecDescriptorRegistryProvider);
  return PropertyConfigRepoImpl(
    dao: dao,
    computeDao: computeDao,
    propertyDao: propertyDao,
    descriptorMap: descriptorMap,
  );
}
