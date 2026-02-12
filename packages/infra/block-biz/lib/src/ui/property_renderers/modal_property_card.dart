import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../domain/property.dart';
import '../../supports/property_descriptor_registry.dart';
import '../property_draft/draft_controller.dart';
import '../spec_renderers/spec_renderer.dart';
import '../spec_renderers/spec_renderer_registry.dart';
import 'components/read_container.dart';
import 'property_card_shell.dart';
import 'property_renderer.dart';

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
    final actions = propertyDescriptor.configSpecDescriptors
        .map((desc) => ref.read(specRendererProvider(desc.id)))
        .whereType<IconSpecRenderer>()
        .map(
          (iconSpec) => IconButton.filledTonal(
            isSelected:
                iconSpec.definition.specId ==
                controllerAsync.value?.currentSpec,
            onPressed: () async {
              final result = await iconSpec.onTap(
                SpecTapParam(
                  specRenderer: iconSpec,
                  context: context,
                  currentKey: propertyKey,
                  currentSpec: iconSpec.definition.specId,
                ),
              );
              if (result != null) {
                notifier.saveSpecAndValue(iconSpec.definition.specId, result);
                notifier.performSave();
              }
            },
            icon: Icon(iconSpec.definition.icon),
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
  }
}
