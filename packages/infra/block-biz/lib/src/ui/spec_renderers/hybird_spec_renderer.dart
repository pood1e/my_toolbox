import 'package:flutter/material.dart';

import '../../domain/property.dart';
import '../../domain/property_config.dart';
import '../spec_renderer.dart';
import 'components/add_source_button.dart';
import 'components/static_sources_area.dart';

class HybirdSpecRenderer extends ContentSpecRendererDefinition {
  final Map<String, String> proceesorRendererMap;
  final double maxHeight;
  final IconData? leadingIcon;

  HybirdSpecRenderer({
    required super.specId,
    required super.icon,
    required this.proceesorRendererMap,
    this.maxHeight = 400,
    this.leadingIcon,
  });

  @override
  List<Widget> extraActions({
    required PropertyConfigBody draft,
    required ValueChanged<PropertyConfigBody> onValueChanged,
    required VoidCallback onSubmit,
  }) => [
    StaticSourceAddIcon(
      specId: specId,
      createDefault: (key, component) {
        draft as HybridPropertyConfig;
        onValueChanged(
          draft.copyWith(processorMap: {...draft.processorMap, key: component}),
        );
        onSubmit();
      },
    ),
  ];

  @override
  Widget build({
    required ContentSpecRenderer specRenderer,
    required PropertyKey currentKey,
    required String currentSpec,
    required PropertyConfigBody draft,
    required ValueChanged<PropertyConfigBody> onValueChanged,
    required ValueChanged<bool> onFocusChanged,
    required VoidCallback onSubmit,
    required VoidCallback onCancel,
  }) {
    draft as HybridPropertyConfig;
    return StaticSourcesArea(
      leadingIcon: leadingIcon,
      map: draft.processorMap,
      builder: (mapKey) {
        final component = draft.processorMap[mapKey]!;
        final renderer =
            specRenderer.proceesorRendererMap[component.component.id]!;
        return renderer.build(
          component.raw,
          (data) {
            onValueChanged(
              draft.copyWith(
                processorMap: {
                  ...draft.processorMap,
                  mapKey: component.copyWith(raw: data),
                },
              ),
            );
            onSubmit();
          },
          onFocusChanged,
          onSubmit,
          onCancel,
        );
      },
      onDelete: (mapKey) async {
        onValueChanged(
          draft.copyWith(processorMap: {...draft.processorMap}..remove(mapKey)),
        );
        onSubmit();
      },
      maxHeight: maxHeight,
    );
  }
}
