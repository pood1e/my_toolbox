import 'package:app_core/di.dart';

import '../ui/node_renderer.dart';
import 'node_renderers/node_editor/node_editor_renderer.dart';

part 'support_node_renderers.g.dart';

@Riverpod(keepAlive: true)
List<NodeRenderer> nodeRendererRegistry(Ref ref) {
  return [NodeEditorRenderer()];
}
