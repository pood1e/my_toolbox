import 'package:app_core/object.dart';

import 'config_spec.dart';
import 'data_type.dart';

part 'property_definition.freezed.dart';

@freezed
abstract class PropertyDefinition with _$PropertyDefinition {
  const factory PropertyDefinition({
    required String propertyId,
    required String dateTypeId,
    required List<String> conficSpecDefinitions,
    @Default(true) bool canBeRule,
  }) = _PropertyDefinition;
}

class PropertyDescriptor<T> {
  final String propertyId;

  final DataType<T> dateType;

  final List<ConfigSpecDescriptor> configSpecDescriptors;

  PropertyDescriptor({
    required this.propertyId,
    required this.dateType,
    required this.configSpecDescriptors,
  });
}
