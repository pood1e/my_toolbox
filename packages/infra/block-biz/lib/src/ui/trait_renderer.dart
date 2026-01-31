import 'package:flutter/material.dart';

import '../domain/shared.dart';

/// 特性渲染器
/// 每个特性应该至少有一个
abstract class TraitRenderer {
  String get id;

  TraitType get traitType;

  Widget render(String traitId);
}
