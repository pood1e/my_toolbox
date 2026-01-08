import 'package:app_core/core.dart';
import 'package:flutter/material.dart';

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
    id: 'memo',
    name: '闪念',
    icon: Icons.flash_on,
    route: '/memo',
  ),
  const AppDefinition(
    id: 'event_timeline',
    name: '时间线',
    icon: Icons.view_timeline,
    route: '/event/timeline',
  ),
  const AppDefinition(
    id: 'lifeflow',
    name: '生活流',
    icon: Icons.stream,
    route: '/lifeflow',
  ),
];
