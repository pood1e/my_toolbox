import 'package:app_core/di.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../state/property_state.dart';
import 'property_editor_definition.dart';

part 'property_editor_registry.g.dart';

@riverpod
List<PropertyEditorDefinition> propertyEditorDefinitions(Ref ref) => [
  InlineEditorDefinition(
    name: 'name',
    icon: Symbols.id_card,
    readBuilder: (state) =>
        state.toWidget(data: (data) => Text(data ?? 'unnamed')),
    onSpecOrEditChanged: (_, _) => PropertyViewLayout.horizontal,
    propertyId: '_name',
  ),
  ActionsEditorDefinition(
    name: 'icon',
    icon: Icons.stars,
    readBuilder: (state) => state.toWidget(
      data: (data) => Wrap(children: [Icon(data ?? Icons.question_mark)]),
    ),
    propertyId: '_icon',
  ),
];

@riverpod
PropertyEditorDefinition propertyEditorDefinition(Ref ref, String propertyId) =>
    ref
        .read(propertyEditorDefinitionsProvider)
        .where((def) => def.propertyId == propertyId)
        .first;
