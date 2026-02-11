import 'package:app_core/di.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../domain/property_config.dart';
import '../../supports/component_registry.dart';
import '../component_renderers/component_renderer.dart';
import '../component_renderers/component_renderer_registry.dart';
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
                entry.key: processorRendererMap[entry.value]!,
          },
          transformerRendererMap: {},
        ),

        // 2. 处理静态 Icon 点击操作 (Icon - Processor)
        SingleStaticSpecIcon d => SpecRenderer.icon(
          definition: d,
          onTap: (param) async {
            final dialog =
                processorRendererMap[d.processorId]! as ProcessorDialog;
            final result = await dialog.showDialog(param.context, param.config);
            if (result != null) {
              return PropertyConfigBody.singleStatic(
                processor: ProcessorComponent(
                  component: processorMap[d.processorId]!,
                  raw: result,
                ),
              );
            }
          },
        ),

        // 3. 处理引用 Icon 点击操作 (Icon - Ref)
        SingleRefSpecIcon d => SpecRenderer.icon(
          definition: d,
          onTap: (param) async {
            final dialog =
                (transformerRendererMap[d.transformerId]! as TransformerDialog);
            final result = await dialog.showRefPicker(
              param.context,
              param.config,
              param.currentKey,
              param.currentSpec,
            );
            if (result != null) {
              return PropertyConfigBody.singleRef(
                transformer: TransformerComponent(
                  component: transformerMap[d.transformerId]!,
                  target: result,
                  raw: null,
                ),
              );
            }
          },
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
