import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../role_service.dart';

class TemplateRole implements Role {
  @override
  List<PropertyConstraint> get constraints => [
    const PropertyConstraint(
      metaId: '_template',
      isMandatory: true,
      config: null,
    ),
  ];

  @override
  IconData get icon => Symbols.video_template;

  @override
  String get id => 'template';

  @override
  String get name => '模板';
}
