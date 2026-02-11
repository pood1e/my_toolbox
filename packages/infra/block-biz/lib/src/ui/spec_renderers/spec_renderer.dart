import 'package:app_core/object.dart';
import 'package:flutter/material.dart';

import '../../domain/property.dart';
import '../../domain/property_config.dart';
import '../component_renderers/component_renderer.dart';

part 'spec_renderer.freezed.dart';

@freezed
abstract class SpecTapParam with _$SpecTapParam {
  const factory SpecTapParam({
    required IconSpecRenderer specRenderer,
    required BuildContext context,
    required PropertyKey currentKey,
    required String currentSpec,
    dynamic config,
  }) = _SpecTapParam;
}

abstract class SpecRendererDefinition {
  String get specId;

  IconData get icon;
}

abstract class IconSpecRendererDefinition<T> extends SpecRendererDefinition {
  @override
  final String specId;

  @override
  final IconData icon;

  IconSpecRendererDefinition({required this.specId, required this.icon});
}

abstract class ContentSpecRendererDefinition extends SpecRendererDefinition {
  @override
  final String specId;

  @override
  final IconData icon;

  Widget build({
    required ContentSpecRenderer specRenderer,
    required PropertyKey currentKey,
    required String currentSpec,
    required PropertyConfigBody draft,
    required ValueChanged<PropertyConfigBody> onValueChanged,
    required ValueChanged<bool> onFocusChanged,
    required VoidCallback onSubmit,
    required VoidCallback onCancel
  });

  ContentSpecRendererDefinition({required this.specId, required this.icon});
}

@freezed
sealed class SpecRenderer with _$SpecRenderer {
  @override
  abstract final SpecRendererDefinition definition;

  const factory SpecRenderer.icon({
    required SpecRendererDefinition definition,
    required Future<dynamic> Function(SpecTapParam) onTap,
  }) = IconSpecRenderer;

  const factory SpecRenderer.content({
    required SpecRendererDefinition definition,
    @Default({}) Map<String, ComponentRenderer> proceesorRendererMap,
    @Default({}) Map<String, ComponentRenderer> transformerRendererMap,
  }) = ContentSpecRenderer;
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
    required VoidCallback onCancel
  }) {
    final cfg = draft as SingleStaticPropertyConfig;
    final renderer =
        specRenderer.proceesorRendererMap[cfg.processor.component.id]!;
    final processorWidget = renderer as ProcessorWidget;
    return processorWidget.builder(
      cfg.processor.raw,
      (data) {
        onValueChanged(
          PropertyConfigBody.singleStatic(
            processor: cfg.processor.copyWith(raw: data),
          ),
        );
      },
      onFocusChanged,
      onSubmit,
      onCancel
    );
  }
}

class SingleStaticSpecIcon extends IconSpecRendererDefinition {
  final String processorId;

  SingleStaticSpecIcon({
    required super.specId,
    required super.icon,
    required this.processorId,
  });

  Future<dynamic> onTap(SpecTapParam param) => param.specRenderer.onTap(param);
}

class SingleRefSpecIcon extends IconSpecRendererDefinition {
  final String transformerId;

  SingleRefSpecIcon({
    required super.specId,
    required super.icon,
    required this.transformerId,
  });

  Future<dynamic> onTap(SpecTapParam param) => param.specRenderer.onTap(param);
}
