import 'package:app_core/di.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../domain/config_spec.dart';
import '../ui/spec_renderers/multi_static_spec_renderer.dart';
import '../ui/spec_renderers/single_ref_spec_renderer.dart';
import '../ui/spec_renderers/single_static_spec_renderer.dart';
import '../ui/spec_renderer.dart';
import 'value_types/role_rule_data_type.dart';

part 'support_config_specs.g.dart';

@Riverpod(keepAlive: true)
List<ConfigSpecDefinition> configSpecDefinitions(Ref ref) => [
  ConfigSpecDefinition.singleStatic(
    id: 'simple_text_config',
    processSpecs: {'simple_text': ComponentSpec(createDefault: () => '')},
  ),
  ConfigSpecDefinition.singleStatic(
    id: 'paragraph_text_config',
    processSpecs: {'simple_text': ComponentSpec(createDefault: () => '')},
  ),
  ConfigSpecDefinition.singleStatic(
    id: 'icon_config',
    processSpecs: {
      'simple_icon': ComponentSpec(createDefault: () => Icons.question_mark),
    },
  ),
  ConfigSpecDefinition.singleRef(
    id: 'icon_ref_config',
    propertyIds: {'_icon'},
    transformerSpecs: {'icon_direct': ComponentSpec(createDefault: () => null)},
  ),
  ConfigSpecDefinition.multiStatic(
    id: 'role_rule_config',
    processorSpecs: {
      'role_rule': ComponentSpec(
        createDefault: () =>
            const RoleRule(propertyId: '_name', type: RoleRuleType.blueprint),
      ),
    },
    aggregatorSpecs: {
      'agg_role_rules': ComponentSpec(createDefault: () => null),
    },
    defaultProcessor: 'role_rule',
    defaultAggregator: 'agg_role_rules',
  ),
];

@Riverpod(keepAlive: true)
List<SpecRendererDefinition> specRendererDefinitions(Ref ref) => [
  SingleStaticSpecContent(
    specId: 'simple_text_config',
    proceesorRendererMap: {'simple_text': 'simple_text'},
    icon: Symbols.id_card,
  ),
  SingleStaticSpecContent(
    specId: 'paragraph_text_config',
    proceesorRendererMap: {'simple_text': 'paragraph'},
    icon: Symbols.id_card,
  ),
  SingleStaticSpecIcon(
    icon: Icons.edit,
    specId: 'icon_config',
    processorId: 'simple_icon',
  ),
  SingleRefSpecIcon(
    icon: Icons.link,
    specId: 'icon_ref_config',
    transformerId: 'icon_direct',
  ),
  MultiStaticSpecRenderer(
    specId: 'role_rule_config',
    icon: Icons.rule_folder,
    leadingIcon: Icons.rule,
    proceesorRendererMap: {'role_rule': 'role_rule_editor'},
  ),
];
