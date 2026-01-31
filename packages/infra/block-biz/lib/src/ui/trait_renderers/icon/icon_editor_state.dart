import 'package:app_core/object.dart';
import 'package:flutter/material.dart';

part 'icon_editor_state.freezed.dart';

@freezed
abstract class IconEditorData with _$IconEditorData {
  const factory IconEditorData({
    required IconData config, // 存图标的序列化数据
    required bool isValid,
  }) = _IconEditorData;
}

extension IconDataExtension on IconData {
  /// 将 IconData 转换为 Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'codePoint': codePoint,
      'fontFamily': fontFamily,
      'fontPackage': fontPackage,
      'matchTextDirection': matchTextDirection,
    };
  }
}

extension IconDataMapExtension on Map<String, dynamic> {
  /// 将 Map (JSON) 还原为 IconData
  /// 如果缺少 codePoint，返回 null
  IconData? toIconData() {
    final codePoint = this['codePoint'] as int?;
    if (codePoint == null) return null;

    return IconData(
      codePoint,
      fontFamily: this['fontFamily'] as String?,
      fontPackage: this['fontPackage'] as String?,
      matchTextDirection: this['matchTextDirection'] as bool? ?? false,
    );
  }
}