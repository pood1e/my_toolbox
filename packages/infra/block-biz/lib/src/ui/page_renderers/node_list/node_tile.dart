import 'package:app_core/di.dart';
import 'package:app_core/route.dart';
import 'package:flutter/material.dart';

import '../../../domain/node.dart';

class NodeTile extends ConsumerWidget {
  final Node _node;

  const NodeTile({super.key, required Node node}) : _node = node;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(child: Text(_node.id.substring(0, 2))),
      title: Text(_node.id),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.push('/node/${_node.id}');
      },
    );
  }
}
