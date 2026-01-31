import 'package:app_core/di.dart';
import 'package:common_ui/component.dart';
import 'package:flutter/material.dart';

import 'dispatchor_controller.dart';

/// 查询node的所有traits
/// 如果有RendererTrait, 按照配置的顺序检查每个Renderer需要的traits是否合法
/// 如果没有, 按照默认优先级顺序显示
class NodeRendererDispatchor {
  Widget render(String nodeId) => _NodeRendererDispatchorWidget(nodeId: nodeId);
}

class _NodeRendererDispatchorWidget extends ConsumerWidget {
  final String _nodeId;

  const _NodeRendererDispatchorWidget({required String nodeId})
    : _nodeId = nodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRendererAsync = ref.watch(
      currentNodeRendererControllerProvider(_nodeId),
    );

    return currentRendererAsync.whenUI(
      data: (currentRenderer) {
        return currentRenderer.render(_nodeId);
      },
    );
  }
}
