import 'package:app_core/di.dart';
import 'package:common_ui/component.dart';
import 'package:flutter/material.dart';

import '../../../domain/property.dart';
import '../../../registry/component_renderer_registry.dart';
import '../../../registry/property_descriptor_registry.dart';
import '../../../ui/property_draft_controller.dart';
import '../../../ui/spec_renderer.dart';
import '../components/property_card_shell.dart';
import '../components/read_container.dart';
import '../property_renderer.dart';

class ModalPropertyCard extends ConsumerWidget {
  final PropertyKey propertyKey;
  final ModalPropertyRenderer renderer;

  const ModalPropertyCard({
    super.key,
    required this.propertyKey,
    required this.renderer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerAsync = ref.watch(
      propertyDraftControllerProvider(propertyKey),
    );
    final notifier = ref.read(
      propertyDraftControllerProvider(propertyKey).notifier,
    );

    final propertyDescriptor = ref.read(
      propertyDescriptorProvider(propertyKey.defId),
    );

    return controllerAsync.whenUI(
      data: (state) {
        final actions = propertyDescriptor!.configSpecDescriptors
            .map((desc) => ref.read(specRendererProvider(desc.id)))
            .whereType<IconSpecRenderer>()
            .map(
              (iconSpec) => iconSpec.definition.build(
                specRenderer: iconSpec,
                currentKey: propertyKey,
                currentSpec: state.currentSpec,
                onValueChanged: (data) {
                  notifier.saveSpecAndValue(iconSpec.definition.specId, data);
                },
                onSubmit: notifier.performSave,
                onCancel: notifier.undo,
              ),
            )
            .toList();
        return PropertyCardShell(
          layout: PropertyViewLayout.horizontal,
          actions: actions,
          propertyKey: propertyKey,
          renderer: renderer,
          // Modal 通常只显示 ReadValue，默认水平即可
          child: ReadContainer(
            propertyKey: propertyKey,
            builder: renderer.readBuilder,
          ),
        );
      },
    );
  }
}
