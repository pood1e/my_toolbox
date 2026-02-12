import 'package:flutter/material.dart';

import '../../domain/property.dart';
import 'component_renderer.dart';
import 'reference_searcher.dart';

class IconRefPicker implements PickerRenderer {
  @override
  String get id => 'icon_direct';

  @override
  Future<dynamic> showPicker(
    BuildContext context,
    PropertyKey currentKey,
    String currentSpec,
  ) => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      content: ReferenceSearcher(
        specId: currentSpec,
        propertyKey: currentKey,
        onSelect: (propertyKey) {
          Navigator.pop(context, propertyKey);
        },
      ),
    ),
  );
}
