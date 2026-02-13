import 'package:flutter/material.dart';

import '../domain/property.dart';

sealed class ComponentRenderer {
  String get id;
}

abstract class ContentRenderer extends ComponentRenderer {
  Widget build(
    dynamic config,
    ValueChanged<dynamic> onValueChanged,
    ValueChanged<bool> onFocusChanged,
    VoidCallback onSubmit,
    VoidCallback onCancel,
  );
}

abstract class PickerRenderer extends ComponentRenderer {
  Future<dynamic> showPicker(
    BuildContext context,
    PropertyKey currentKey,
    String currentSpec,
  );
}