import 'package:app_core/di.dart';
import 'package:app_core/route.dart';
import 'package:common_ui/component.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import '../../../storage/node_service.dart';
import '../../component_widget.dart';
import '../node/node_tile.dart';

part 'node_list.g.dart';

class NodeListComponent implements ComponentWidget {
  @override
  String get id => 'node_list';

  @override
  WidgetType get type => WidgetType.page;

  @override
  ComponentBuilder get builder =>
      (_) => const NodeListWidget();
}

@riverpod
class NodeListController extends _$NodeListController {
  @override
  Stream<List<String>> build() async* {
    final service = await ref.watch(nodeServiceProvider.future);
    yield* service.watchNodes();
  }

  Future<String> addNode() async {
    final service = await ref.read(nodeServiceProvider.future);
    return await service.addNode();
  }
}

class NodeListWidget extends ConsumerWidget {
  const NodeListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodesAsync = ref.watch(nodeListControllerProvider);
    final notifier = ref.read(nodeListControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('node list')),
      body: nodesAsync.whenUI(
        data: (nodes) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacings.l),
          child: ListView.builder(
            itemBuilder: (_, index) =>
                NodeTileWidget(config: NodeTileConfig(nodeId: nodes[index])),
            itemCount: nodes.length,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final id = await notifier.addNode();
          if (context.mounted) {
            context.push('/node/$id');
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
