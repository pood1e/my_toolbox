import 'package:flutter/material.dart';

import '../../domain/property_definition.dart';
import '../../domain/source_definition.dart';

class IconProperty extends PropertyDefinition<IconData> {
  @override
  String get propertyId => '_icon';

  @override
  String get dateTypeId => 'icon';

  @override
  List<SourceDefinition> get sourceDefinitions => [
    const SourceDefinition.singleStatic(
      name: 'static',
      processorId: 'direct_icon',
    ),
  ];
}
