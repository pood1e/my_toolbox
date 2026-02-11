import 'package:flutter/material.dart';

import '../../domain/config_spec.dart';
import '../../domain/property_definition.dart';

class IconProperty extends PropertyDefinition<IconData> {
  @override
  String get propertyId => '_icon';

  @override
  String get dateTypeId => 'icon';

  @override
  List<String> get conficSpecDefinitions => ['icon_config'];
}

final iconConfigSpec = ConfigSpecDefinition.singleStatic(
  id: 'icon_config',
  processSpecs: {
    'simple_icon': ComponentSpec(createDefault: () => Icons.question_mark),
  },
  defaultProcessor: 'simple_icon',
);
