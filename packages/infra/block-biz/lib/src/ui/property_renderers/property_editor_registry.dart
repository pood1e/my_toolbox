import 'package:app_core/di.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../state/property_state.dart';
import 'property_renderer.dart';

part 'property_editor_registry.g.dart';

@riverpod
List<PropertyRenderer> propertyRenderers(Ref ref) => [
  InlinePropertyRenderer(
    name: 'name',
    icon: Symbols.id_card,
    readBuilder: (state) =>
        state.toWidget(data: (data) => Text(data ?? 'unnamed')),
    whenSpecAndEdit: (_, _) => PropertyViewLayout.horizontal,
    propertyId: '_name',
  ),
  ModalPropertyRenderer(
    name: 'icon',
    icon: Icons.stars,
    readBuilder: (state) => state.toWidget(
      data: (data) => Wrap(children: [Icon(data ?? Icons.question_mark)]),
    ),
    propertyId: '_icon',
  ),
  InlinePropertyRenderer(
    name: 'description',
    icon: Symbols.description,
    readBuilder: (state) =>
        state.toWidget(data: (data) => Text(data ?? 'no description')),
    whenSpecAndEdit: (_, _) => PropertyViewLayout.vertical,
    propertyId: '_description',
  ),
];

@riverpod
PropertyRenderer propertyRenderer(Ref ref, String propertyId) => ref
    .read(propertyRenderersProvider)
    .where((def) => def.propertyId == propertyId)
    .first;
