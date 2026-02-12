import 'package:app_core/di.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../supports/component_registry.dart';
import '../component_renderers/component_renderer.dart';
import '../component_renderers/component_renderer_registry.dart';
import 'single_ref_spec_renderer.dart';
import 'single_static_spec_renderer.dart';
import 'spec_renderer.dart';

part 'spec_renderer_registry.g.dart';

@Riverpod(keepAlive: true)
List<SpecRendererDefinition> specRendererDefinitions(Ref ref) => [
  SingleStaticSpecContent(
    specId: 'name_config',
    proceesorRendererMap: {'simple_text': 'simple_text'},
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
];

@Riverpod(keepAlive: true)
Map<String, SpecRenderer> specRendererRegistry(Ref ref) {
  final definitions = ref.read(specRendererDefinitionsProvider);
  final processorRendererMap = ref.read(processorRendererRegistryProvider);
  final transformerRendererMap = ref.read(transformerRendererRegistryProvider);
  final processorMap = ref.read(processorRegistryProvider);
  final transformerMap = ref.read(transformerRegistryProvider);

  return {
    for (final def in definitions)
      def.specId: switch (def) {
        // 1. 处理内联内容编辑器 (Content)
        SingleStaticSpecContent d => SpecRenderer.content(
          definition: d,
          proceesorRendererMap: {
            for (final entry in d.proceesorRendererMap.entries)
              if (processorRendererMap.containsKey(entry.value))
                entry.key:
                    processorRendererMap[entry.value]! as ContentRenderer,
          },
          transformerRendererMap: {},
        ),

        // 2. 处理静态 Icon 点击操作 (Icon - Processor)
        SingleStaticSpecIcon d => SpecRenderer.icon(
          definition: d,
          renderer: processorRendererMap[d.processorId]! as PickerRenderer,
          component: processorMap[d.processorId]!,
        ),

        // 3. 处理引用 Icon 点击操作 (Icon - Ref)
        SingleRefSpecIcon d => SpecRenderer.icon(
          definition: d,
          renderer: transformerRendererMap[d.transformerId]! as PickerRenderer,
          component: transformerMap[d.transformerId]!,
        ),
        // 4. 处理未知的定义类型
        _ => throw UnimplementedError(
          'Unknown SpecRendererDefinition type: ${def.runtimeType}',
        ),
      },
  };
}

@riverpod
SpecRenderer? specRenderer(Ref ref, String specId) {
  final registry = ref.read(specRendererRegistryProvider);
  return registry[specId];
}
