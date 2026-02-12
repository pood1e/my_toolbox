import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:material_symbols_icons/symbols_map.dart';

import '../../domain/property.dart';
import 'component_renderer.dart';

class SimpleIconPicker implements PickerRenderer {
  @override
  String get id => 'simple_icon';

  @override
  Future<dynamic> showPicker(
    BuildContext context,
    PropertyKey currentKey,
    String currentSpec,
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
