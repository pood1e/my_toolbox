import 'package:app_core/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';

import 'component_renderer.dart';

class SimpleIconRenderer implements ProcessorRenderer<IconData> {
  @override
  String get id => 'simple_icon';

  @override
  Widget build(
    IconData config,
    ValueChanged<IconData> onValueChanged,
    ValueChanged<bool> onFocusChanged,
    VoidCallback onSubmit,
  ) => SimpleIconWidget(onValueChanged: onValueChanged, onSumbit: onSubmit);
}

class SimpleIconWidget extends ConsumerWidget {
  final ValueChanged<IconData> _onValueChanged;
  final VoidCallback _onSumbit;

  const SimpleIconWidget({
    super.key,
    required ValueChanged<IconData> onValueChanged,
    required VoidCallback onSumbit,
  }) : _onValueChanged = onValueChanged,
       _onSumbit = onSumbit;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    onPressed: () async {
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
      final data = icon?.data;
      if (data != null) {
        _onValueChanged(data);
        _onSumbit();
      }
    },
    icon: const Icon(Icons.edit),
  );
}
