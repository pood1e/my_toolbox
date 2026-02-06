import 'package:flutter/material.dart';

import '../../../domain/property.dart';

/// 默认编辑器支持
abstract class EditorDescriptor<C, T> {
  String get propertyId;

  C get defaultConfig;

  IconData get icon;

  String get name;

  // 只读视图
  Widget Function(PropertyKey)? get valueWidgetBuilder => null;

  // 配置视图
  Widget Function(PropertyKey) get configWidgetBuilder;
}
