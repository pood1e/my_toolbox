import 'package:app_core/di.dart';
import 'package:common_ui/component.dart';
import 'package:flutter/material.dart';

import '../../../../domain/property.dart';
import '../../../property_draft/draft_controller.dart';
import '../../../spec_renderers/spec_renderer.dart';
import '../../../spec_renderers/spec_renderer_registry.dart';

class EditorContainer extends ConsumerWidget {
  final PropertyKey propertyKey;
  final String specId;

  const EditorContainer({
    super.key,
    required this.propertyKey,
    required this.specId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftController = ref.watch(
      propertyDraftControllerProvider(propertyKey).notifier,
    );
    final draftStateAsync = ref.watch(
      propertyDraftControllerProvider(propertyKey),
    );

    return draftStateAsync.whenUI(
      data: (state) {
        final specRenderer = ref.watch(specRendererRegistryProvider)[specId];
        if (specRenderer == null || specRenderer is! ContentSpecRenderer) {
          return Text(
            'Missing renderer for spec: $specId',
            style: const TextStyle(color: Colors.red),
          );
        }
        final definition =
            specRenderer.definition as ContentSpecRendererDefinition;
        return definition.build(
          specRenderer: specRenderer,
          draft: state.draft,
          onValueChanged: draftController.updateDraft,
          onFocusChanged: draftController.setFocus,
          onSubmit: draftController.performSave,
          currentSpec: state.currentSpec,
          currentKey: propertyKey,
        );
      },
    );
  }
}
