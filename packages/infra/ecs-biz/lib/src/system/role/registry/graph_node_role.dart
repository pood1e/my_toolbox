import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../meta/registry/icon_meta.dart';
import '../../meta/registry/text_meta.dart';
import '../role_service.dart';

class GraphNodeRole implements Role {
  @override
  List<PropertyConstraint> get constraints => [
    const PropertyConstraint(
      metaId: '_name',
      isMandatory: true,
      config: TextConfig(text: 'unnamed'),
    ),
    const PropertyConstraint(
      metaId: '_icon',
      isMandatory: false,
      config: IconConfig(mode: IconMode.pick, picked: Icons.question_mark),
    ),
  ];

  @override
  IconData get icon => Symbols.graph_1;

  @override
  String get id => 'graph_node';

  @override
  String get name => '图节点';
}
