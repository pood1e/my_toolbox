import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../role_service.dart';

class ConceptRole implements Role {
  @override
  List<PropertyConstraint> get constraints => [
    const PropertyConstraint(metaId: '_name', isMandatory: true),
    const PropertyConstraint(metaId: '_description', isMandatory: true),
  ];

  @override
  IconData get icon => Symbols.ad;

  @override
  String get id => 'concept';

  @override
  String get name => '概念';
}
