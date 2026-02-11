import 'config_spec.dart';
import 'data_type.dart';

abstract class PropertyDefinition<T> {
  /// unique
  String get propertyId;

  String get dateTypeId;

  List<String> get conficSpecDefinitions;
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
