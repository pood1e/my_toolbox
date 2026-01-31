import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../../domain/shared.dart';
import '../../../models/models.dart';
import '../../trait_renderers/trait_renderer_registry.dart';

final _traitEditorMap = {
  TraitType.name: 'name_editor',
  TraitType.icon: 'icon_editor',
};

class TraitEditTile extends ConsumerWidget {
  final Trait _trait;

  const TraitEditTile({super.key, required Trait trait}) : _trait = trait;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rendererId = _traitEditorMap[_trait.traitType];
    if (rendererId == null) {
      return Card(child: Text('not support for ${_trait.traitType.name}'));
    }
    final traitRenderer = ref.read(useTraitRendererProvider(rendererId));
    if (traitRenderer == null) {
      return Card(child: Text('not found trait renderer: $rendererId'));
    }
    return traitRenderer.render(_trait.id);
  }
}
