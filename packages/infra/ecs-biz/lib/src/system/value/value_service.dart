import 'package:app_core/di.dart';
import 'package:app_core/object.dart';

import '../compute/compute_service.dart';
import '../meta/property_meta_service.dart';
import 'data/value_dao.dart';
import 'data_types/simple_text.dart';
import 'impl/value_service_impl.dart';

part 'value_service.freezed.dart';
part 'value_service.g.dart';

@freezed
abstract class PropertyVal with _$PropertyVal {
  const factory PropertyVal({
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
  Stream<List<PropertyVal>> watchValues(List<PropertyId> ids);

  Future<PropertyVal?> getValue(PropertyId propertyId);

  Future<void> update(PropertyId propertyId, PropertyVal val);

  Future<void> delete(PropertyId propertyId);

  Future<void> markAsDirty(Set<PropertyId> propertyIds);

  Future<void> markAsError(Map<PropertyId, ComputeError> errorMap);
}

@riverpod
Future<ValueService> valueService(Ref ref) async {
  final dao = await ref.watch(valueDaoProvider.future);
  final metaService = ref.watch(propertyMetaServiceProvider);
  return ValueServiceImpl(
    dataTypes: [SimpleText()],
    dao: dao,
    metaService: metaService,
  );
}
