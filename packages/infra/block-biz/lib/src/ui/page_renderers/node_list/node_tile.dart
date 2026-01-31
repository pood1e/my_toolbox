import 'package:app_core/di.dart';
import 'package:app_core/route.dart';
import 'package:flutter/material.dart';

import '../../../models/models.dart';

class NodeTile extends ConsumerWidget {
  final Node _node;

  const NodeTile({super.key, required Node node}) : _node = node;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _node.isValid ? Colors.green : Colors.grey,
        child: Text(_node.id.substring(0, 2)),
      ),
      title: Text(_node.id),
      subtitle: Text(_node.isValid ? 'Valid' : 'Invalid'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.push('/node/${_node.id}');
      },
    );
  }
}
