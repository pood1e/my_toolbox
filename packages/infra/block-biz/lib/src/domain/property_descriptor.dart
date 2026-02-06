import 'package:flutter/material.dart';

import 'type_descriptor.dart';

/// property -> valueType
/// valueType hardcode
/// property expanded
abstract class PropertyDescriptor<C, T> {
  /// unique
  String get propertyId;

  String get name;

  TypeDescriptor<C, T> get typeDescriptor;

  // typeRender

  // configRender
}

/// 拥有默认值
abstract class PropertyDefaultEditConfig<C> {
  String get propertyId;

  C get defaultConfig;

  IconData get icon;
}
