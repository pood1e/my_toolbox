import 'package:app_core/di.dart';
import 'package:common_ui/component.dart';
import 'package:flutter/material.dart';

import '../../../domain/property.dart';
import '../../../mappers/property_mapper.dart';
import '../../../registry/property_descriptor_registry.dart';
import '../../../ui/property_draft_controller.dart';
import '../../../ui/property_state.dart';

class ReadContainer extends ConsumerWidget {
  final PropertyKey propertyKey;
  final Widget Function(PropertyState state) builder;

  const ReadContainer({
    super.key,
    required this.propertyKey,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final descriptor = ref.watch(propertyDescriptorProvider(propertyKey.defId));
    final propertyAsync = ref.watch(watchPropertyProvider(propertyKey));
    return propertyAsync.whenUI(
      data: (property) {
        final state = property.toState(descriptor!.dateType.definition);
        return builder(state);
      },
    );
  }
}
