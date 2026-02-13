import 'package:flutter/material.dart';

import '../../../ui/node_renderer.dart';
import 'node_editor.dart';

class NodeEditorRenderer implements NodeRenderer {
  @override
  String get id => 'node_editor';

  @override
  int get priority => 0;

  @override
  Widget render(String nodeId) => NodeEditor(nodeId: nodeId);
}
