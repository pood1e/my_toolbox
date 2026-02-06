import 'package:app_core/di.dart';
import 'package:common_ui/component.dart';
import 'package:flutter/material.dart';

import '../../../domain/property.dart';
import '../../../supports/property_def_registry.dart';
import 'node_editor_controller.dart';

class PropertyEditTile extends ConsumerWidget {
  final PropertyKey _propertyKey;

  const PropertyEditTile({super.key, required PropertyKey propertyKey})
    : _propertyKey = propertyKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertyAsync = ref.watch(watchPropertyProvider(_propertyKey));
    final descriptor = ref.read(propertyDescriptorProvider(_propertyKey.defId));

    return Card(
      child: ListTile(
        leading: Text(descriptor.name),
        title: propertyAsync.whenUI(
          data: (state) {
            return Text(state.toString());
          },
        ),
      ),
    );
  }
}
