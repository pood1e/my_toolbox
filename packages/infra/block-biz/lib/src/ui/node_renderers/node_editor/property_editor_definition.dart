// File: ui/node_renderers/node_editor/property_editor_descriptor.dart

import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../state/property_state.dart';

/// 1. 顶层描述符：定义一个属性支持的所有能力
/// 属性编辑器描述符

enum PropertyViewLayout {
  horizontal, // Label --- Content (Actions)
  vertical, // Label \n Content \n (Actions)
}

abstract class PropertyBasicInfo {
  String get propertyId;

  String get name;

  IconData get icon;
}

abstract class PropertyViewerWidget {
  Widget Function(PropertyState state) get readBuilder;
}

sealed class PropertyEditorDefinition implements PropertyBasicInfo {
  @override
  final String propertyId;
  @override
  final String name;
  @override
  final IconData icon;

  PropertyEditorDefinition({
    required this.name,
    required this.icon,
    required this.propertyId,
  });
}

class InlineEditorDefinition extends PropertyEditorDefinition
    implements PropertyViewerWidget {
  @override
  final Widget Function(PropertyState<dynamic> state) readBuilder;

  final PropertyViewLayout Function(String, bool)? onSpecOrEditChanged;

  InlineEditorDefinition({
    required super.name,
    required super.icon,
    required this.readBuilder,
    this.onSpecOrEditChanged,
    required super.propertyId,
  });
}

class ModalEditorDefinition extends PropertyEditorDefinition
    implements PropertyViewerWidget {
  @override
  final Widget Function(PropertyState<dynamic> state) readBuilder;
  final dynamic Function(BuildContext context, WidgetRef ref) onEdit;

  ModalEditorDefinition({
    required super.name,
    required super.icon,
    required this.readBuilder,
    required super.propertyId,
    required this.onEdit,
  });
}

class ActionsEditorDefinition extends PropertyEditorDefinition
    implements PropertyViewerWidget {
  @override
  final Widget Function(PropertyState<dynamic> state) readBuilder;

  ActionsEditorDefinition({
    required super.name,
    required super.icon,
    required this.readBuilder,
    required super.propertyId,
  });
}

class DirectEditorDefinition extends PropertyEditorDefinition {
  final PropertyViewLayout Function(String)? onSpecOrEditChanged;

  DirectEditorDefinition({
    required super.name,
    required super.icon,
    this.onSpecOrEditChanged,
    required super.propertyId,
  });
}
