import 'package:flutter/material.dart';

import '../../domain/compute_engine.dart';
import '../../domain/property.dart';
import '../../domain/property_config.dart';
import '../spec_renderer.dart';

class SingleRefSpecIcon extends IconSpecRendererDefinition {
  final String transformerId;

  SingleRefSpecIcon({
    required super.specId,
    required super.icon,
    required this.transformerId,
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
          PropertyConfigBody.singleRef(
            transformer: TransformerComponent(
              component: specRenderer.component as Transformer,
              target: result,
              raw: null,
            ),
          ),
        );
        onSubmit();
        return;
      }
    },
    icon: icon,
    iconSpec: specId,
    selected: currentSpec == specId,
  );
}
