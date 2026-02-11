import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../../../domain/property.dart';
import '../../../property_draft/draft_controller.dart';
import '../components/edit_container.dart';
import '../components/property_card_shell.dart';
import '../components/property_error_card.dart';
import '../components/property_loading_card.dart';
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

    return draftStateAsync.when(
      data: (draftState) {
        final layout = definition.onSpecOrEditChanged(0);

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
      loading: () => PropertyLoadingCard(name: definition.name),
      error: (e, s) =>
          PropertyErrorCard(name: definition.name, error: e.toString()),
    );
  }
}
