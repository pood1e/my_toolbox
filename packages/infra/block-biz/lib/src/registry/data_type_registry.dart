import 'package:app_core/di.dart';

import '../domain/data_type.dart';
import '../supports/support_components.dart';
import '../supports/support_data_types.dart';

part 'data_type_registry.g.dart';

@Riverpod(keepAlive: true)
List<DataType> dataTypes(Ref ref) {
  final definitions = ref.read(dataTypeDefinitionsProvider);
  final processors = ref.read(processorsProvider);
  final transformers = ref.read(transformersProvider);
  final aggregators = ref.read(aggregatorsProvider);
  return definitions
      .map(
        (def) => DataType(
          id: def.id,
          definition: def,
          processors: processors.where((p) => p.typeId == def.id).toSet(),
          transformers: transformers.where((p) => p.tTypeId == def.id).toSet(),
          aggregators: aggregators.where((p) => p.tTypeId == def.id).toSet(),
        ),
      )
      .toList();
}

@Riverpod(keepAlive: true)
Map<String, DataType> dataTypeRegistry(Ref ref) {
  final dataTypes = ref.read(dataTypesProvider);
  return {for (final p in dataTypes) p.id: p};
}

@riverpod
DataType? dataType(Ref ref, String id) =>
    ref.read(dataTypeRegistryProvider)[id];
