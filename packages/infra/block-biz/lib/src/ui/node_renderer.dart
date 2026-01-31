import 'package:flutter/material.dart';

import '../domain/shared.dart';

/// 节点渲染器
abstract class NodeRenderer {
  String get id;

  int get priority => 0;

  Set<TraitType> get requiredTraits;

  Widget render(String nodeId);
}
