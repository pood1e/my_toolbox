import 'data_type.dart';
import 'source_definition.dart';

abstract class PropertyDefinition<T> {
  /// unique
  String get propertyId;

  String get dateTypeId;

  List<SourceDefinition> get sourceDefinitions;
}

class PropertyDescriptor<T> {
  final String propertyId;

  final DataType<T> dateType;

  final List<SourceDescriptor> sourceDescriptors;

  PropertyDescriptor({
    required this.propertyId,
    required this.dateType,
    required this.sourceDescriptors,
  });
}
