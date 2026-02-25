import 'package:app_core/di.dart';
import 'package:common_ui/component.dart';
import 'package:flutter/material.dart';

import '../../../meta/property_meta_service.dart';
import '../../../role/role_service.dart';
import '../../component_widget.dart';
import 'property_card.dart';
import 'text_editor.dart';

class DescriptionPropertyComponent implements PropertyWidget {
  @override
  PropertyComponentBuilder get builder =>
      (nodeId, _) => DescriptionEditorWidget(nodeId: nodeId);

  @override
  String get id => 'description_editor';

  @override
  String get metaId => '_description';
}

class DescriptionEditorWidget extends ConsumerWidget {
  final PropertyId _propertyId;

  DescriptionEditorWidget({super.key, required String nodeId})
    : _propertyId = PropertyId(nodeId: nodeId, metaId: '_description');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valAsync = ref.watch(textEditorControllerProvider(_propertyId));
    final notifier = ref.read(
      textEditorControllerProvider(_propertyId).notifier,
    );
    final mandatoryAsync = ref.watch(checkMetaIsMandatoryProvider(_propertyId));

    return PropertyCardWidget(
      config: PropertyCardConfig(
        metaId: '_description',
        actions: [
          if (!(mandatoryAsync.value ?? true))
            IconButton(
              onPressed: notifier.deleteProperty,
              icon: const Icon(Icons.delete),
            ),
        ],
        content: valAsync.whenUI(
          data: (config) => TextFormField(
            initialValue: config.text,
            onChanged: notifier.updateText,
            maxLines: null,
            minLines: 3,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }
}
