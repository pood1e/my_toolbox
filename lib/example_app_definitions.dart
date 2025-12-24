import 'package:flutter/material.dart';
import 'package:framework_biz/starter.dart';

/// 示例 App 定义列表
final List<AppDefinition> kExampleApps = [
  const AppDefinition(
    id: 'todo',
    name: '待办事项',
    icon: Icons.check_circle_outline,
    route: '/apps/todo',
  ),
  const AppDefinition(
    id: 'weather',
    name: '天气预报',
    icon: Icons.wb_sunny_outlined,
    route: '/apps/weather',
  ),
  const AppDefinition(
    id: 'calculator',
    name: '计算器',
    icon: Icons.calculate_outlined,
    route: '/apps/calculator',
  ),
  const AppDefinition(
    id: 'notes',
    name: '备忘录',
    icon: Icons.note_alt_outlined,
    route: '/apps/notes',
  ),
  const AppDefinition(
    id: 'gallery',
    name: '相册',
    icon: Icons.photo_library_outlined,
    route: '/apps/gallery',
  ),
  const AppDefinition(
    id: 'settings_shortcut',
    name: '系统设置',
    icon: Icons.settings_outlined,
    route: '/settings', // 直接跳转到现有的设置页
  ),
];
