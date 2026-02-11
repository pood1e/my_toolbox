import '../../domain/config_spec.dart';
import '../../domain/property_definition.dart';
import '../processor/simple_text_processor.dart';

class NameProperty extends PropertyDefinition<String> {
  @override
  String get propertyId => '_name';

  @override
  String get dateTypeId => 'text';

  @override
  List<String> get conficSpecDefinitions => ['name_config'];
}

final nameConfigSpec = ConfigSpecDefinition.singleStatic(
  id: 'name_config',
  processSpecs: {
    'simple_text': ComponentSpec(
      createDefault: () => const SimpleText(data: 'unnamed'),
    ),
  },
  defaultProcessor: 'simple_text',
);
