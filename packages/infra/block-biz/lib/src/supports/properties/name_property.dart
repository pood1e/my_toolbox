import '../../domain/property_definition.dart';
import '../../domain/source_definition.dart';

class NameProperty extends PropertyDefinition<String> {
  @override
  String get propertyId => '_name';

  @override
  String get dateTypeId => 'text';

  @override
  List<SourceDefinition> get sourceDefinitions => [
    const SourceDefinition.singleStatic(
      name: 'simple',
      processorId: 'direct_text',
    ),
  ];
}
