import 'package:app_core/di.dart';
import 'package:app_core/route.dart';
import 'package:common_ui/component.dart';
import 'package:flutter/material.dart';

import 'node_controller.dart';
import 'node_tile.dart';

class NodeListPage extends ConsumerWidget {
  const NodeListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodesAsync = ref.watch(nodeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Node List')),
      body: nodesAsync.whenUI(
        data: (nodes) {
          if (nodes.isEmpty) return const Center(child: Text('Empty list'));
          return ListView.builder(
            itemCount: nodes.length,
            itemBuilder: (context, index) {
              return NodeTile(node: nodes[index]);
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final notifier = ref.read(nodeControllerProvider.notifier);
          final id = await notifier.createNode();
          if (context.mounted) {
            context.push('/node/$id');
          }
        },
      ),
    );
  }
}
