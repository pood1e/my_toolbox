import 'package:flutter/material.dart';

import '../../domain/compute_engine.dart';
import '../../domain/property.dart';
import '../../domain/property_config.dart';
import '../spec_renderer.dart';

class SingleStaticSpecIcon extends IconSpecRendererDefinition {
  final String processorId;

  SingleStaticSpecIcon({
    required super.specId,
    required super.icon,
    required this.processorId,
  });

  @override
  Widget build({
    required IconSpecRenderer specRenderer,
    required PropertyKey currentKey,
    required String currentSpec,
    required ValueChanged<PropertyConfigBody> onValueChanged,
    required VoidCallback onSubmit,
    required VoidCallback onCancel,
  }) => SpecIconWidget(
    onPressed: (ctx, iconSpec) async {
      final result = await specRenderer.renderer.showPicker(
        ctx,
        currentKey,
        iconSpec,
      );
      if (result != null) {
        onValueChanged(
          PropertyConfigBody.singleStatic(
            processor: ProcessorComponent(
              component: specRenderer.component as Processor,
              raw: result,
            ),
          ),
        );
        onSubmit();
      }
    },
    icon: icon,
    iconSpec: specId,
    selected: currentSpec == specId,
  );
}

class SingleStaticSpecContent extends ContentSpecRendererDefinition {
  final Map<String, String> proceesorRendererMap;

  SingleStaticSpecContent({
    required super.specId,
    required super.icon,
    required this.proceesorRendererMap,
  });

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
    draft as SingleStaticPropertyConfig;
    final renderer =
        specRenderer.proceesorRendererMap[draft.processor.component.id]!;
    return renderer.build(
      draft.processor.raw,
      (data) {
        onValueChanged(
          PropertyConfigBody.singleStatic(
            processor: draft.processor.copyWith(raw: data),
          ),
        );
      },
      onFocusChanged,
      onSubmit,
      onCancel,
    );
  }
}
