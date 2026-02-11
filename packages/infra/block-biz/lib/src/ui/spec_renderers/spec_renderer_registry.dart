import 'package:app_core/di.dart';

import '../component_renderers/component_renderer_registry.dart';
import 'spec_renderer.dart';

part 'spec_renderer_registry.g.dart';

@Riverpod(keepAlive: true)
List<SpecRendererDefinition> specRendererDefinitions(Ref ref) => [
  SingleStaticSpecRendererDefinition(
    specId: 'name_config',
    proceesorRendererMap: {'simple_text': 'simple_text'},
  ),
  SingleStaticSpecRendererDefinition(
    specId: 'icon_config',
    proceesorRendererMap: {'simple_icon': 'simple_icon'},
  ),
];

@Riverpod(keepAlive: true)
Map<String, SpecRenderer> specRendererRegistry(Ref ref) {
  final definitions = ref.read(specRendererDefinitionsProvider);
  final processorRendererMap = ref.read(processorRendererRegistryProvider);
  return {
    for (final def in definitions)
      def.specId: SpecRenderer(
        definition: def,
        proceesorRendererMap: {
          for (final entry in def.proceesorRendererMap.entries)
            entry.key: processorRendererMap[entry.value]!,
        },
      ),
  };
}
