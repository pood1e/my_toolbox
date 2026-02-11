import 'package:app_core/di.dart';

import 'component_renderer.dart';
import 'simple_icon_renderer.dart';
import 'simple_text_renderer.dart';

part 'component_renderer_registry.g.dart';

@Riverpod(keepAlive: true)
List<ProcessorRenderer> processorRenderers(Ref ref) => [SimpleTextRenderer(), SimpleIconRenderer()];

@Riverpod(keepAlive: true)
Map<String, ProcessorRenderer> processorRendererRegistry(Ref ref) {
  final renderers = ref.read(processorRenderersProvider);
  return {for (final r in renderers) r.id: r};
}
