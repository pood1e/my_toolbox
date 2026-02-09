// File: ui/node_renderers/node_editor/property_editor_descriptor.dart

import 'package:flutter/material.dart';

import '../../../domain/property.dart';
import '../../../domain/property_config.dart';
import '../../../domain/stored_config.dart';

/// 1. 顶层描述符：定义一个属性支持的所有能力
class PropertyEditorDescriptor {
  final String propertyId;
  final String name;
  final IconData icon;

  /// 支持的模式列表
  final List<EditorModeSpec> supportedModes;

  PropertyEditorDescriptor({
    required this.propertyId,
    required this.name,
    required this.icon,
    required this.supportedModes,
  });

  EditorModeSpec get defaultMode => supportedModes.first;
}

/// 2. 模式规格说明 (Specification)
/// 这是一个 Sealed Class，用于描述不同模式的元数据
sealed class EditorModeSpec {
  SourceMode get mode;
  String get label;
  IconData get icon;

  /// 工厂方法：生成该模式下的【默认配置】
  /// 当用户点击切换模式时调用
  PropertyConfig createDefaultConfig(PropertyKey key);
}

// --- 具体实现 ---

class StaticModeSpec extends EditorModeSpec {
  @override
  final SourceMode mode = SourceMode.singleStatic;
  @override
  final String label;
  @override
  final IconData icon;

  final String processorId;
  final Map<String, dynamic> defaultRawData;

  StaticModeSpec({
    this.label = 'Manual',
    this.icon = Icons.edit,
    required this.processorId,
    this.defaultRawData = const {}, // 默认值，如 {'data': ''}
  });

  @override
  PropertyConfig createDefaultConfig(PropertyKey key) => PropertyConfig.singleStatic(
      key: key,
      source: StaticSourceConfig(
        processorId: processorId,
        raw: defaultRawData,
      ),
    );
}

class RefModeSpec extends EditorModeSpec {
  @override
  final SourceMode mode = SourceMode.singleRef;
  @override
  final String label;
  @override
  final IconData icon;

  final String defaultTransformerId;

  RefModeSpec({
    this.label = 'Reference',
    this.icon = Icons.link,
    required this.defaultTransformerId,
  });

  @override
  PropertyConfig createDefaultConfig(PropertyKey key) => PropertyConfig.singleRef(
      key: key,
      target: null, // 默认未选中
      transformer: TransformerConfig(
        transformerId: defaultTransformerId,
        raw: {},
      ),
    );
}