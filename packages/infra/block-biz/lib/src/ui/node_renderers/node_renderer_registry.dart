import 'package:app_core/di.dart';

import '../node_renderer.dart';
import 'node_editor/node_editor_renderer.dart';

part 'node_renderer_registry.g.dart';

@Riverpod(keepAlive: true)
List<NodeRenderer> nodeRendererRegistry(Ref ref) {
  return [NodeEditorRenderer()];
}
