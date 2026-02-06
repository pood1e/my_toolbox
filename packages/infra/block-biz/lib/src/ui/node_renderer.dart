import 'package:flutter/material.dart';

/// 节点渲染器
abstract class NodeRenderer {
  String get id;

  int get priority => 0;

  Widget render(String nodeId);
}
