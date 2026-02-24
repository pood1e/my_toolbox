import 'package:app_core/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:material_symbols_icons/symbols_map.dart';

import '../../component_widget.dart';

class SimpleIconPicker implements ComponentAction<void, IconData> {
  const SimpleIconPicker();

  @override
  Future<IconData?> func(
    BuildContext context,
    WidgetRef ref,
    void config,
  ) async {
    final icon = await showIconPicker(
      context,
      configuration: SinglePickerConfiguration(
        iconPackModes: [
          IconPack.allMaterial,
          IconPack.fontAwesomeIcons,
          IconPack.cupertino,
          IconPack.lineAwesomeIcons,
          IconPack.custom,
        ],
        customIconPack: {
          for (final entry in materialSymbolsMap.entries)
            entry.key: IconPickerIcon(
              name: entry.key,
              data: entry.value,
              pack: 'material_symbols',
            ),
        },
      ),
    );

    return icon?.data;
  }
}
