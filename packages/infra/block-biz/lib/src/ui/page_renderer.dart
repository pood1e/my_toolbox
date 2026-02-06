import 'package:flutter/material.dart';

/// 页面渲染器
abstract class PageRenderer {
  String get id;
  
  Widget render();
}
