import 'package:flutter/material.dart';

import '../../component_widget.dart';

class IconDataView implements DataTypeWidget {
  @override
  ComponentBuilder get builder =>
      (cfg) => Icon(cfg);

  @override
  String get id => 'icon_view';

  @override
  String get dataTypeId => 'icon';

  @override
  bool get isDefault => true;
}
