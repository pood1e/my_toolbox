import 'package:app_core/di.dart';
import 'package:common_ui/component.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../domain/property.dart';
import '../../../common_property_controller.dart';
import '../../../state/property_state.dart';
import '../property_editor_controller.dart';
import '../property_editor_descriptor.dart';
import '../property_editor_registry.dart';

final nameEditor = InlineEditorDescriptor<String>(
  propertyId: '_name',
  name: 'Name',
  icon: Symbols.id_card,
  defaultConfig: 'unnamed',
  savePolicy: SavePolicy.manual,
  viewerBuilder: (key) => _NameViewerWidget(propertyKey: key),
  editorBuilder: (key) => _NameEditorWidget(propertyKey: key),
  validator: (value) {
    if (value.isEmpty) {
      return 'Name cannot be empty'; // 返回错误信息
    }
    return null; // 返回 null 表示校验通过
  },
);

class _NameViewerWidget extends ConsumerWidget {
  final PropertyKey _propertyKey;

  const _NameViewerWidget({required PropertyKey propertyKey})
    : _propertyKey = propertyKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final descriptor = ref.read(
      propertyEditorDescriptorProvider(_propertyKey.defId),
    );
    return ref
        .watch(watchPropertyProvider(_propertyKey))
        .whenUI(
          data: (state) => Text(state.getValue() ?? descriptor.defaultConfig),
        );
  }
}

class _NameEditorWidget extends ConsumerWidget {
  final PropertyKey _propertyKey;

  const _NameEditorWidget({required PropertyKey propertyKey})
    : _propertyKey = propertyKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(
      propertyEditorControllerProvider(_propertyKey),
    );
    final controller = ref.read(
      propertyEditorControllerProvider(_propertyKey).notifier,
    );

    return stateAsync.when(
      data: (state) => TextFormField(
        initialValue: state.current,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Enter name',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
          errorText: state.validationError, // 显示校验错误
        ),
        // 更新草稿
        onChanged: controller.updateDraft,
      ),
      loading: () => const LinearProgressIndicator(),
      error: (err, _) => Text('Error: $err'),
    );
  }
}
