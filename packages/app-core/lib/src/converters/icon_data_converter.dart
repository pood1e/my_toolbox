import 'package:flutter/material.dart';

import '../../object.dart';

class IconDataConverter
    implements JsonConverter<IconData, Map<String, dynamic>> {
  const IconDataConverter();

  @override
  IconData fromJson(Map<String, dynamic> json) => IconData(
    json['codePoint'] as int,
    fontFamily: json['fontFamily'] as String?,
    fontPackage: json['fontPackage'] as String?,
    matchTextDirection: json['matchTextDirection'] as bool? ?? false,
  );

  @override
  Map<String, dynamic> toJson(IconData object) => {
    'codePoint': object.codePoint,
    'fontFamily': object.fontFamily,
    'fontPackage': object.fontPackage,
    'matchTextDirection': object.matchTextDirection,
  };
}