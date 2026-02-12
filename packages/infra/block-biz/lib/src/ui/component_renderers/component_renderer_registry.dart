import 'package:app_core/di.dart';

import 'component_renderer.dart';
import 'icon_ref_picker.dart';
import 'simple_icon_picker.dart';
import 'simple_text_editor.dart';

part 'component_renderer_registry.g.dart';

@Riverpod(keepAlive: true)
List<ComponentRenderer> processorRenderers(Ref ref) => [
  SimpleTextRenderer(),
  SimpleIconPicker(),
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
