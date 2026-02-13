import 'package:flutter/material.dart';

import '../../ui/property_state.dart';

/// 编排 spec
sealed class PropertyRenderer {
  // spec有无编辑内容
  // 右上角action可以切换spec
  // spec 无内容时需要展示只读组件
  // spec 全有内容时, 使用inline
  final String propertyId;
  final String name;
  final IconData icon;

  PropertyRenderer({
    required this.propertyId,
    required this.name,
    required this.icon,
  });
}

abstract class PropertyViewerWidget {
  Widget Function(PropertyState state) get readBuilder;
}

enum PropertyViewLayout { horizontal, vertical }

/// 无read
class DirectPropertyRenderer extends PropertyRenderer {
  PropertyViewLayout Function(String)? onSpecOrEditChanged = (_) =>
      PropertyViewLayout.vertical;

  DirectPropertyRenderer({
    required super.name,
    required super.icon,
    this.onSpecOrEditChanged,
    required super.propertyId,
  });
}

/// modal: 无edit面板
class ModalPropertyRenderer extends PropertyRenderer
    implements PropertyViewerWidget {
  @override
  final Widget Function(PropertyState<dynamic> state) readBuilder;
  final PropertyViewLayout layout;

  ModalPropertyRenderer({
    required super.name,
    required super.icon,
    required super.propertyId,
    required this.readBuilder,
    this.layout = PropertyViewLayout.vertical,
  });
}

/// 校验: 必须所有spec都是content
class InlinePropertyRenderer extends PropertyRenderer
    implements PropertyViewerWidget {
  @override
  final Widget Function(PropertyState<dynamic> state) readBuilder;

  PropertyViewLayout Function(String, bool)? whenSpecAndEdit = (_, _) =>
      PropertyViewLayout.vertical;

  InlinePropertyRenderer({
    required super.name,
    required super.icon,
    required this.readBuilder,
    this.whenSpecAndEdit,
    required super.propertyId,
  });
}

/// 先只支持一种spec
class ExpansionPropertyRenderer extends PropertyRenderer
    implements PropertyViewerWidget {
  @override
  final Widget Function(PropertyState<dynamic> state) readBuilder;

  PropertyViewLayout Function(String, bool)? whenSpecAndEdit = (_, _) =>
  PropertyViewLayout.vertical;

  ExpansionPropertyRenderer({
    required super.name,
    required super.icon,
    required this.readBuilder,
    this.whenSpecAndEdit,
    required super.propertyId,
  });
}