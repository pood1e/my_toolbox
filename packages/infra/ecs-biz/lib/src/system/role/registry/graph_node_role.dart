import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../role_service.dart';

class GraphNodeRole implements Role {
  @override
  List<PropertyConstraint> get constraints => [
    const PropertyConstraint(metaId: '_name', isMandatory: true),
    const PropertyConstraint(metaId: '_icon', isMandatory: false),
  ];

  @override
  IconData get icon => Symbols.graph_1;

  @override
  String get id => 'graph_node';

  @override
  String get name => '图节点';
}
