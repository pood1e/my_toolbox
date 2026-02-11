import 'package:app_core/di.dart';
import 'package:common_ui/component.dart';
import 'package:flutter/material.dart';

import '../../../../domain/property.dart';
import '../../../property_draft/draft_controller.dart';
import '../components/edit_container.dart';
import '../components/property_card_shell.dart';
import '../property_editor_definition.dart';

class DirectPropertyCard extends ConsumerWidget {
  final PropertyKey propertyKey;
  final DirectEditorDefinition definition;

  const DirectPropertyCard({
    super.key,
    required this.propertyKey,
    required this.definition,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftStateAsync = ref.watch(
      propertyDraftControllerProvider(propertyKey),
    );

    return draftStateAsync.whenUI(
      data: (draftState) {
        final layout = definition.onSpecOrEditChanged == null
            ? PropertyViewLayout.horizontal
            : definition.onSpecOrEditChanged!(draftState.currentSpec);

        return PropertyCardShell(
          definition: definition,
          layout: layout,
          actions: const [],
          propertyKey: propertyKey,
          child: EditorContainer(
            propertyKey: propertyKey,
            specId: draftState.currentSpec,
          ),
        );
      },
    );
  }
}
