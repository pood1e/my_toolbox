import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../../domain/property.dart';

// --- Enums ---
enum PropertyViewLayout { vertical, horizontal }

enum SavePolicy { immediate, debounce, manual }

// --- Base Descriptor ---
sealed class PropertyEditorDescriptor<T> {
  // 公共字段定义在基类，子类不再重复定义
  final String propertyId;
  final String name;
  final IconData icon;
  final T defaultConfig;
  final PropertyViewLayout viewLayout;

  /// 校验器：返回 null 表示通过，返回错误字符串表示失败
  final String? Function(T value)? validator;

  /// 头部操作栏插槽
  final List<Widget> Function(BuildContext, WidgetRef, PropertyKey)?
  actionsBuilder;

  const PropertyEditorDescriptor({
    required this.propertyId,
    required this.name,
    required this.icon,
    required this.defaultConfig,
    this.viewLayout = PropertyViewLayout.horizontal,
    this.validator,
    this.actionsBuilder,
  });

  /// 获取保存策略 (子类必须实现或覆盖)
  SavePolicy get savePolicy;
}

// --- Subclasses ---

/// 1. Inline: 原地编辑
final class InlineEditorDescriptor<T> extends PropertyEditorDescriptor<T> {
  final PropertyViewLayout? _editLayout;

  PropertyViewLayout get editLayout => _editLayout ?? viewLayout;

  @override
  final SavePolicy savePolicy;

  final Widget Function(PropertyKey key) viewerBuilder;
  final Widget Function(PropertyKey key) editorBuilder;

  const InlineEditorDescriptor({
    required super.propertyId,
    required super.name,
    required super.icon,
    required super.defaultConfig,
    required this.viewerBuilder,
    required this.editorBuilder,
    super.viewLayout, // 默认 horizontal
    super.validator,
    super.actionsBuilder,
    PropertyViewLayout? editLayout,
    this.savePolicy = SavePolicy.manual,
  }) : _editLayout = editLayout;
}

/// 2. Modal: 弹窗编辑
final class ModalEditorDescriptor<T> extends PropertyEditorDescriptor<T> {
  final Widget Function(PropertyKey key) viewerBuilder;
  final Future<T?> Function(BuildContext, WidgetRef) onEdit;

  const ModalEditorDescriptor({
    required super.propertyId,
    required super.name,
    required super.icon,
    required super.defaultConfig,
    required this.viewerBuilder,
    required this.onEdit,
    super.viewLayout,
    super.validator,
    super.actionsBuilder,
  });

  @override
  SavePolicy get savePolicy => SavePolicy.manual;
}

/// 3. Direct: 直接交互
final class DirectEditorDescriptor<T> extends PropertyEditorDescriptor<T> {
  final Widget Function(PropertyKey key) widgetBuilder;

  const DirectEditorDescriptor({
    required super.propertyId,
    required super.name,
    required super.icon,
    required super.defaultConfig,
    required this.widgetBuilder,
    super.viewLayout,
    super.validator,
    super.actionsBuilder,
  });

  @override
  SavePolicy get savePolicy => SavePolicy.immediate;
}
