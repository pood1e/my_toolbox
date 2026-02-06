import 'package:flutter/material.dart';

import '../../domain/property_descriptor.dart';
import '../../domain/type_descriptor.dart';
import '../compute_engines/direct_engine.dart';
import '../converters/typed_json_converter.dart';
import '../value_types/simple_json_type.dart';

class IconProperty extends PropertyDescriptor<IconData, IconData> {
  @override
  String get propertyId => '_icon';

  @override
  TypeDescriptor<IconData, IconData> get typeDescriptor =>
      SimpleJsonType<IconData, IconData>(
        jsonConfigConverter: IconDataConverter(),
        jsonValueConverter: IconDataConverter(),
        engine: DirectEngine<IconData>(),
      );
}

class IconDataConverter implements TypedJsonConverter<IconData> {
  @override
  IconData decode(Map<String, dynamic> config) => config.toIconData()!;

  @override
  Map<String, dynamic> encode(IconData t) => t.toJson();
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
