import 'package:flutter/material.dart';

import '../../component_widget.dart';

class TextDataView extends DataTypeWidget {
  @override
  ComponentBuilder get builder =>
      (text) => Text(text);

  @override
  String get dataTypeId => 'simple_text';

  @override
  String get id => 'text_view';

  @override
  bool get isDefault => true;
}
