import 'package:app_core/object.dart';
import 'package:flutter/material.dart';

import '../../domain/compute_engine.dart';
import '../../domain/property.dart';
import '../../domain/property_config.dart';
import '../component_renderers/component_renderer.dart';

part 'spec_renderer.freezed.dart';

sealed class SpecRendererDefinition {
  final String specId;

  final IconData icon;

  SpecRendererDefinition({required this.specId, required this.icon});
}

abstract class IconSpecRendererDefinition extends SpecRendererDefinition {
  Widget build({
    required IconSpecRenderer specRenderer,
    required PropertyKey currentKey,
    required String currentSpec,
    required ValueChanged<PropertyConfigBody> onValueChanged,
    required VoidCallback onSubmit,
    required VoidCallback onCancel,
  });

  IconSpecRendererDefinition({required super.specId, required super.icon});
}

abstract class ContentSpecRendererDefinition extends SpecRendererDefinition {
  Widget build({
    required ContentSpecRenderer specRenderer,
    required PropertyKey currentKey,
    required String currentSpec,
    required PropertyConfigBody draft,
    required ValueChanged<PropertyConfigBody> onValueChanged,
    required ValueChanged<bool> onFocusChanged,
    required VoidCallback onSubmit,
    required VoidCallback onCancel,
  });

  ContentSpecRendererDefinition({required super.specId, required super.icon});
}

@freezed
sealed class SpecRenderer with _$SpecRenderer {
  @override
  abstract final SpecRendererDefinition definition;

  const factory SpecRenderer.icon({
    required IconSpecRendererDefinition definition,
    required PickerRenderer renderer,
    required Configurable component,
  }) = IconSpecRenderer;

  const factory SpecRenderer.content({
    required ContentSpecRendererDefinition definition,
    @Default({}) Map<String, ContentRenderer> proceesorRendererMap,
    @Default({}) Map<String, ContentRenderer> transformerRendererMap,
  }) = ContentSpecRenderer;
}

class SpecIconWidget extends StatelessWidget {
  final Future<void> Function(BuildContext, String) _onPressed;
  final IconData _icon;
  final bool _selected;
  final String _iconSpec;

  const SpecIconWidget({
    super.key,
    required Future<void> Function(BuildContext, String) onPressed,
    required IconData icon,
    bool selected = false,
    required String iconSpec,
  }) : _onPressed = onPressed,
       _icon = icon,
       _selected = selected,
       _iconSpec = iconSpec;

  @override
  Widget build(BuildContext context) => _selected
      ? IconButton.filledTonal(
          onPressed: () async {
            await _onPressed(context, _iconSpec);
          },
          icon: Icon(_icon),
        )
      : IconButton(
          onPressed: () async {
            await _onPressed(context, _iconSpec);
          },
          icon: Icon(_icon),
        );
}
