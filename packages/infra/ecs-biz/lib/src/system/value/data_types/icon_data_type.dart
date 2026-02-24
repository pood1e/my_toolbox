import 'package:app_core/object.dart';
import 'package:flutter/material.dart';

import '../value_service.dart';

class IconDataType implements DataType<IconData> {
  final _converter = const IconDataConverter();

  @override
  IconData? fromDb(value) => _converter.fromJson(value);

  @override
  String get id => 'icon';

  @override
  toDb(IconData value) => _converter.toJson(value);
}
