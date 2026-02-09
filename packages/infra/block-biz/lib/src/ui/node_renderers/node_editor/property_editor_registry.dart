import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import 'property_editor_descriptor.dart';

part 'property_editor_registry.g.dart';

@riverpod
List<PropertyEditorDescriptor> propertyEditorDescriptors(Ref ref) => [
  // 1. Name 属性：只允许手动输入
  PropertyEditorDescriptor(
    propertyId: '_name',
    name: 'Name',
    icon: Icons.badge,
    supportedModes: [
      StaticModeSpec(
        label: 'Manual',
        processorId: 'direct_text',
        defaultRawData: {'data': 'New Node'},
      ),
    ],
  ),

  // 2. Icon 属性：允许手动选，也允许引用
  PropertyEditorDescriptor(
    propertyId: '_icon',
    name: 'Icon',
    icon: Icons.stars,
    supportedModes: [
      StaticModeSpec(
        label: 'Pick Icon',
        icon: Icons.grid_view,
        processorId: 'direct_icon', // 对应 IconPickerEditor
      ),
      RefModeSpec(
        label: 'Use Reference',
        icon: Icons.link,
        defaultTransformerId: 'direct_icon', // 复用 Transformer
      ),
    ],
  ),
];

@riverpod
PropertyEditorDescriptor propertyEditorDescriptor(Ref ref, String propertyId) =>
    ref
        .read(propertyEditorDescriptorsProvider)
        .where((def) => def.propertyId == propertyId)
        .first;
