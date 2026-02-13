import 'package:app_core/di.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../domain/property_definition.dart';
import '../ui/property_state.dart';
import 'property_renderers/property_renderer.dart';
import 'value_types/role_rules_data_type.dart';

part 'support_properties.g.dart';

@Riverpod(keepAlive: true)
List<PropertyDefinition> propertyDefinitions(Ref ref) => [
  const PropertyDefinition(
    propertyId: '_name',
    dateTypeId: 'text',
    conficSpecDefinitions: ['simple_text_config'],
  ),
  const PropertyDefinition(
    propertyId: '_icon',
    dateTypeId: 'icon',
    conficSpecDefinitions: ['icon_config', 'icon_ref_config'],
  ),
  const PropertyDefinition(
    propertyId: '_description',
    dateTypeId: 'text',
    conficSpecDefinitions: ['paragraph_text_config'],
  ),
  const PropertyDefinition(
    propertyId: '_role_rule',
    dateTypeId: 'role_rules',
    conficSpecDefinitions: ['role_rule_config'],
  ),
];

@riverpod
List<PropertyRenderer> propertyRenderers(Ref ref) => [
  InlinePropertyRenderer(
    name: 'name',
    icon: Symbols.id_card,
    readBuilder: (state) =>
        state.toWidget(data: (data) => Text(data ?? 'unnamed')),
    whenSpecAndEdit: (_, _) => PropertyViewLayout.horizontal,
    propertyId: '_name',
  ),
  ModalPropertyRenderer(
    name: 'icon',
    icon: Icons.stars,
    readBuilder: (state) => state.toWidget(
      data: (data) => Wrap(children: [Icon(data ?? Icons.question_mark)]),
    ),
    propertyId: '_icon',
  ),
  InlinePropertyRenderer(
    name: 'description',
    icon: Symbols.description,
    readBuilder: (state) =>
        state.toWidget(data: (data) => Text(data ?? 'no description')),
    whenSpecAndEdit: (_, _) => PropertyViewLayout.vertical,
    propertyId: '_description',
  ),
  ExpansionPropertyRenderer(
    name: 'role_rule',
    icon: Icons.rule_folder,
    readBuilder: (state) => state.toWidget(
      data: (data) {
        data as RoleRules;
        return Wrap(
          spacing: AppSpacings.s,
          runSpacing: AppSpacings.s,
          children: data.rules
              .map(
                (rule) => Chip(
                  label: Text('${rule.propertyId} | ${rule.type.name}'),
                  visualDensity: VisualDensity.compact,
                ),
              )
              .toList(),
        );
      },
    ),
    propertyId: '_role_rule',
  ),
];
