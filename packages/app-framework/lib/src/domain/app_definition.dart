import 'package:app_core/object.dart';
import 'package:flutter/material.dart';

part 'app_definition.freezed.dart';

/// App 入口定义
@freezed
abstract class AppDefinition with _$AppDefinition {
  const factory AppDefinition({
    required String id,
    required String name,
    required IconData icon,
    required String route,
  }) = _AppDefinition;
}
