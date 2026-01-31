import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

/// 页面渲染器
abstract class PageRenderer {
  String get id;

  // Set<TraitType> get supportTraits;

  Widget render();
}
