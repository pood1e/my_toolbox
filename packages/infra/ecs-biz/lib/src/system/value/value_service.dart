import 'package:app_core/di.dart';
import 'package:app_core/object.dart';

import '../compute/compute_service.dart';
import '../meta/property_meta_service.dart';
import '../storage/ecs_database.dart';
import 'data/value_dao.dart';
import 'data_types/icon_data_type.dart';
import 'data_types/roles_data_type.dart';
import 'data_types/simple_text.dart';
import 'impl/value_service_impl.dart';

part 'value_service.freezed.dart';
part 'value_service.g.dart';

@freezed
abstract class PropertyVal with _$PropertyVal {
  const factory PropertyVal({
    required PropertyId propertyId,

    dynamic value,

    required ValueStatus status,

    String? extra,
  }) = _PropertyVal;
}

enum ValueStatus { normal, dirty, error }

enum StorageType { bool, int, real, text, json, str }

abstract class DataType<T> {
  String get id;

  T? fromDb(dynamic value);

  dynamic toDb(T value);
}

mixin PropertyValueMeta on PropertyMeta {
  String get dataTypeId;

  StorageType get storageType;
}

abstract class ValueService {
  PropertyVal? valueEntityToVal(PropertyValEntity entity);

  Stream<List<PropertyVal>> watchValues(Set<PropertyId> ids);

  Stream<PropertyVal?> watchValue(PropertyId id);

  Future<PropertyVal?> getValue(PropertyId propertyId);

  Future<void> update(PropertyVal val);

  Future<void> delete(PropertyId propertyId);

  Future<void> markAsDirty(Set<PropertyId> propertyIds);

  Future<void> markAsError(Map<PropertyId, ComputeError> errorMap);

  Future<Set<PropertyId>> filterValueValid(Set<PropertyId> propertyIds);
}

@riverpod
Future<ValueService> valueService(Ref ref) async {
  final dao = await ref.watch(valueDaoProvider.future);
  final metaService = ref.watch(propertyMetaServiceProvider);
  return ValueServiceImpl(
    dataTypes: [SimpleText(), IconDataType(), RolesDataType()],
    dao: dao,
    metaService: metaService,
  );
}

@riverpod
Stream<PropertyVal?> watchValue(Ref ref, PropertyId id) async* {
  final srv = await ref.watch(valueServiceProvider.future);
  yield* srv.watchValue(id);
}
