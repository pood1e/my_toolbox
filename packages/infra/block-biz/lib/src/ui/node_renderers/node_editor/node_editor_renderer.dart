import 'package:flutter/material.dart';

import '../../../domain/shared.dart';
import '../../node_renderer.dart';
import 'node_editor.dart';

class NodeEditorRenderer implements NodeRenderer {
  @override
  String get id => 'node_editor';

  @override
  Set<TraitType> get requiredTraits => {};

  @override
  int get priority => 0;

  @override
  Widget render(String nodeId) => NodeEditor(nodeId: nodeId);
}
