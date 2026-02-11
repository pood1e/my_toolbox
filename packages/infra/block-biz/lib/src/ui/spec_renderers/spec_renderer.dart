import 'package:app_core/object.dart';
import 'package:flutter/material.dart';

import '../../domain/property_config.dart';
import '../component_renderers/component_renderer.dart';

part 'spec_renderer.freezed.dart';

/// todo: switch draft map
/// 编排与切换
abstract class SpecRendererDefinition {
  String get specId;

  Map<String, String> get proceesorRendererMap => {};

  Map<String, String> get transformerRendererMap => {};

  Map<String, String> get aggregatorRendererMap => {};

  Widget build(
    SpecRenderer specRenderer,
    PropertyConfigBody draft,
    ValueChanged<PropertyConfigBody> onValueChanged,
    ValueChanged<bool> onFocusChanged,
    VoidCallback onSubmit,
  );
}

@freezed
abstract class SpecRenderer with _$SpecRenderer {
  const factory SpecRenderer({
    required SpecRendererDefinition definition,
    @Default({}) Map<String, ProcessorRenderer> proceesorRendererMap,
  }) = _SpecRenderer;
}

class SingleStaticSpecRendererDefinition extends SpecRendererDefinition {
  @override
  final Map<String, String> proceesorRendererMap;
  @override
  final String specId;

  SingleStaticSpecRendererDefinition({
    required this.proceesorRendererMap,
    required this.specId,
  });

  @override
  Widget build(
    SpecRenderer specRenderer,
    PropertyConfigBody draft,
    ValueChanged<PropertyConfigBody> onValueChanged,
    ValueChanged<bool> onFocusChanged,
    VoidCallback onSubmit,
  ) {
    final cfg = draft as SingleStaticPropertyConfig;
    return specRenderer.proceesorRendererMap[cfg.processor.component.id]!.build(
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
    );
  }
}
