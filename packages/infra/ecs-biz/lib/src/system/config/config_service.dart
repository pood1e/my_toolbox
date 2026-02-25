import 'package:app_core/di.dart';
import 'package:framework_api/framework_api.dart';

import '../meta/property_meta_service.dart';
import '../relation/relation_service.dart';
import '../sync/crdt_service.dart';
import '../value/value_service.dart';
import 'data/property_config_dao.dart';
import 'impl/config_service_impl.dart';

part 'config_service.g.dart';

mixin PropertyConfigMeta<T> on PropertyMeta {
  T fromDb(Map<String, dynamic> cfg);

  Map<String, dynamic> toDb(T cfg);

  Map<String, bool> buildUpdateMap(T cfg, T? snapshot) => {};

  T? get defaultConfig => null;
}

abstract class ConfigService {
  Future<dynamic> get(PropertyId propertyId);

  Stream<dynamic> watch(PropertyId propertyId);

  Stream<Set<String>> watchMetasByNode(String nodeId);

  Future<void> create(PropertyId propertyId, dynamic config);

  Future<void> update(PropertyId propertyId, dynamic snapshot, dynamic config);

  Future<void> delete(PropertyId propertyId);

  Future<Set<PropertyId>> checkExist(Set<PropertyId> propertyIds);
}

@riverpod
Future<ConfigService> configService(Ref ref) async {
  final dao = await ref.watch(propertyConfigDaoProvider.future);
  final metaService = ref.watch(propertyMetaServiceProvider);
  final crdtService = await ref.watch(crdtServiceProvider.future);
  final valueService = await ref.watch(valueServiceProvider.future);
  final relationService = await ref.watch(relationServiceProvider.future);
  final timeService = await ref.watch(serverTimeServiceProvider.future);
  return ConfigServiceImpl(
    dao: dao,
    metaService: metaService,
    crdtService: crdtService,
    timeService: timeService,
    valueService: valueService,
    relationService: relationService,
  );
}

@riverpod
Stream<dynamic> watchPropertyConfig(Ref ref, PropertyId propertyId) async* {
  final service = await ref.watch(configServiceProvider.future);
  yield* service.watch(propertyId);
}
