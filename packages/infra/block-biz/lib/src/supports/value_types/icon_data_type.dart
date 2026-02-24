import 'dart:convert';

import 'package:app_core/object.dart';
import 'package:flutter/material.dart';

import '../../domain/data_type.dart';
import '../../domain/stored_value.dart';

class IconDataType implements DataTypeDefinition<IconData> {
  @override
  IconData? fromDb(value) {
    if (value == null) return null;
    final Map<String, dynamic> json = jsonDecode(value);
    return json.toIconData()!;
  }

  @override
  String get id => 'icon';

  @override
  StorageType get storageType => StorageType.json;

  @override
  toDb(IconData value) => jsonEncode(value.toJson());
}

extension IconDataExtension on IconData {
  /// 将 IconData 转换为 Map (JSON)
  Map<String, dynamic> toJson() => {
    'codePoint': codePoint,
    'fontFamily': fontFamily,
    'fontPackage': fontPackage,
    'matchTextDirection': matchTextDirection,
  };
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

