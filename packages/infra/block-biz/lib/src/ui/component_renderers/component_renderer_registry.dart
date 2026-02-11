import 'package:app_core/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';

import '../../supports/processor/simple_text_processor.dart';
import 'component_renderer.dart';
import 'reference_searcher.dart';
import 'simple_text_editor.dart';

part 'component_renderer_registry.g.dart';

@Riverpod(keepAlive: true)
List<ComponentRenderer> processorRenderers(Ref ref) => [
  ProcessorWidget<SimpleText>(
    id: 'simple_text',
    builder: (config, onValueChanged, onFocusChanged, onSubmit) =>
        SimpleTextEditor(
          text: config,
          onChanged: onValueChanged,
          onFocusChanged: onFocusChanged,
          onSumbit: onSubmit,
        ),
  ),
  ProcessorDialog<IconData>(
    id: 'simple_icon',
    showDialog: (context, _) async {
      final icon = await showIconPicker(
        context,
        configuration: const SinglePickerConfiguration(
          iconPackModes: [
            IconPack.material,
            IconPack.fontAwesomeIcons,
            IconPack.cupertino,
            IconPack.lineAwesomeIcons,
          ],
        ),
      );
      return icon?.data;
    },
  ),
];

@Riverpod(keepAlive: true)
Map<String, ComponentRenderer> processorRendererRegistry(Ref ref) {
  final renderers = ref.read(processorRenderersProvider);
  return {for (final r in renderers) r.id: r};
}

@Riverpod(keepAlive: true)
List<ComponentRenderer> transformerRenderers(Ref ref) => [
  TransformerDialog(
    id: 'icon_direct',
    showRefPicker: (ctx, config, currentKey, currentSpec) => showDialog(
      context: ctx,
      builder: (context) => AlertDialog(
        content: ReferenceSearcher(
          specId: currentSpec,
          propertyKey: currentKey,
          onSelect: (propertyKey) {
            Navigator.pop(context, propertyKey);
          },
        ),
      ),
    ),
  ),
];

@Riverpod(keepAlive: true)
Map<String, ComponentRenderer> transformerRendererRegistry(Ref ref) {
  final renderers = ref.read(transformerRenderersProvider);
  return {for (final r in renderers) r.id: r};
}
