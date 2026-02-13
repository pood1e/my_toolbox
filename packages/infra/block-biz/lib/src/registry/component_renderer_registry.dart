import 'package:app_core/di.dart';

import '../supports/support_config_specs.dart';
import '../ui/component_renderer.dart';
import '../supports/processor/renders/paragraph_editor.dart';
import '../supports/processor/renders/role_rule_editor.dart';
import '../supports/processor/renders/simple_icon_picker.dart';
import '../supports/processor/renders/simple_text_editor.dart';
import '../supports/transformer/renders/icon_ref_picker.dart';
import '../ui/spec_renderers/multi_static_spec_renderer.dart';
import '../ui/spec_renderers/single_ref_spec_renderer.dart';
import '../ui/spec_renderers/single_static_spec_renderer.dart';
import '../ui/spec_renderer.dart';
import 'component_registry.dart';

part 'component_renderer_registry.g.dart';

@Riverpod(keepAlive: true)
List<ComponentRenderer> processorRenderers(Ref ref) => [
  SimpleTextRenderer(),
  SimpleIconPicker(),
  ParagraphRenderer(),
  RoleRuleRenderer(),
];

@Riverpod(keepAlive: true)
Map<String, ComponentRenderer> processorRendererRegistry(Ref ref) {
  final renderers = ref.read(processorRenderersProvider);
  return {for (final r in renderers) r.id: r};
}

@Riverpod(keepAlive: true)
List<ComponentRenderer> transformerRenderers(Ref ref) => [IconRefPicker()];

@Riverpod(keepAlive: true)
Map<String, ComponentRenderer> transformerRendererRegistry(Ref ref) {
  final renderers = ref.read(transformerRenderersProvider);
  return {for (final r in renderers) r.id: r};
}

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

        MultiStaticSpecRenderer d => SpecRenderer.content(
          definition: d,
          proceesorRendererMap: {
            for (final entry in d.proceesorRendererMap.entries)
              if (processorRendererMap.containsKey(entry.value))
                entry.key:
                processorRendererMap[entry.value]! as ContentRenderer,
          },
          transformerRendererMap: {},
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
