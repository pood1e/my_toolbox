import 'package:app_core/di.dart';
import 'package:common_ui/component.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';

import '../../../../domain/property.dart';
import '../property_editor_controller.dart';
import '../property_editor_descriptor.dart';

final iconEditor = ModalEditorDescriptor<IconData>(
  propertyId: '_icon',
  name: 'Icon',
  icon: Icons.stars,
  defaultConfig: Icons.question_mark,
  viewerBuilder: (key) => _IconViewerWidget(propertyKey: key),
  onEdit: (context, ref) async {
    // Pick an icon
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
);

class _IconViewerWidget extends ConsumerWidget {
  final PropertyKey propertyKey;

  const _IconViewerWidget({required this.propertyKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(propertyEditorControllerProvider(propertyKey));

    return stateAsync.whenUI(
      data: (state) => Wrap(children: [Icon(state.current)]),
    );
  }
}
