import 'package:app_core/di.dart';
import 'package:app_core/route.dart';
import 'package:common_ui/component.dart';
import 'package:flutter/material.dart';

import '../../../domain/node.dart';
import '../../state/property_state.dart';
import 'node_controller.dart';

class NodeTile extends ConsumerWidget {
  final Node _node;

  const NodeTile({super.key, required Node node}) : _node = node;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodeStateAsync = ref.watch(nodeStateProvider(_node.id));
    return nodeStateAsync.whenUI(
      data: (nodeState) => ListTile(
        leading: nodeState.icon.toWidget(
          data: Icon.new,
          uninitialized: const Icon(Icons.question_mark),
        ),
        title: nodeState.name.toWidget(
          data: Text.new,
          uninitialized: const Text('unnamed'),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.push('/node/${_node.id}');
        },
      ),
    );
  }
}
