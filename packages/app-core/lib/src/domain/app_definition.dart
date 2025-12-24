import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
