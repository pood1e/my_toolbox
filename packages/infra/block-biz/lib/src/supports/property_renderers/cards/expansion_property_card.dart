import 'package:app_core/di.dart';
import 'package:common_ui/component.dart';
import 'package:flutter/material.dart';

import '../../../domain/property.dart';
import '../../../registry/component_renderer_registry.dart';
import '../../../ui/property_draft_controller.dart';
import '../../../ui/spec_renderer.dart';
import '../components/edit_container.dart';
import '../components/expansion_card_shell.dart';
import '../components/read_container.dart';
import '../property_renderer.dart';

class ExpansionPropertyCard extends ConsumerWidget {
  final PropertyKey propertyKey;
  final ExpansionPropertyRenderer renderer;

  const ExpansionPropertyCard({
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

    return controllerAsync.whenUI(
      data: (state) {
        final specRenderer =
            ref.read(specRendererRegistryProvider)[state.currentSpec]
                as ContentSpecRenderer;

        return ExpansionCardShell(
          actions: specRenderer.definition.extraActions(
            draft: state.draft,
            onValueChanged: notifier.updateDraft,
            onSubmit: notifier.performSave,
          ),
          propertyKey: propertyKey,
          renderer: renderer,
          expandedChild: EditorContainer(
            propertyKey: propertyKey,
            specId: state.currentSpec,
          ),
          child: ReadContainer(
            propertyKey: propertyKey,
            builder: renderer.readBuilder,
          ),
        );
      },
    );
  }
}
