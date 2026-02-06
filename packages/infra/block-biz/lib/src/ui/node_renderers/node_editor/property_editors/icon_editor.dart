import 'package:app_core/di.dart';
import 'package:common_ui/component.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';

import '../../../../domain/property.dart';
import '../../../../supports/property_def_registry.dart';
import '../../../common_property_controller.dart';
import '../property_edit_support.dart';

class IconEditor extends EditorDescriptor<IconData, IconData> {
  @override
  String get propertyId => '_icon';

  @override
  IconData get defaultConfig => Icons.question_mark;

  @override
  String get name => 'icon';

  @override
  IconData get icon => Icons.stars;

  @override
  Widget Function(PropertyKey) get configWidgetBuilder =>
      (key) => _IconEditorWidget(propertyKey: key);
}

class _IconEditorWidget extends ConsumerWidget {
  final PropertyKey _propertyKey;

  const _IconEditorWidget({required PropertyKey propertyKey})
    : _propertyKey = propertyKey;

  Future<void> _pickAndSave(BuildContext context, WidgetRef ref) async {
    IconPickerIcon? result = await showIconPicker(
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

    if (result != null) {
      IconData pickedIcon = result.data;
      final notifier = ref.read(
        commonConfigControllerProvider(_propertyKey).notifier,
      );
      await notifier.fullUpdate(pickedIcon);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerAsync = ref.watch(
      commonConfigControllerProvider(_propertyKey),
    );

    final descriptor = ref.read(propertyDescriptorProvider(_propertyKey.defId));
    return controllerAsync.whenUI(
      data: (config) => Card(
        child: ListTile(
          title: Icon(
            descriptor.typeDescriptor.configConverter.decode(config.configs),
          ),
          onTap: () {
            _pickAndSave(context, ref);
          },
        ),
      ),
    );
  }
}
