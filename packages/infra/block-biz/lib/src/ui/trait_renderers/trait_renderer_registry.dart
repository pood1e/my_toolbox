import 'package:app_core/di.dart';
import 'package:app_core/utils.dart';

import '../trait_renderer.dart';
import 'icon/icon_editor_renderer.dart';
import 'name/name_editor_renderer.dart';

part 'trait_renderer_registry.g.dart';

@Riverpod(keepAlive: true)
List<TraitRenderer> traitRendererRegistry(Ref ref) {
  return [NameEditorRenderer(), IconEditorRenderer()];
}

@riverpod
TraitRenderer? useTraitRenderer(Ref ref, String rendererId) {
  return ref
      .read(traitRendererRegistryProvider)
      .firstWhereOrNull((renderer) => renderer.id == rendererId);
}
