import 'package:app_core/core.dart';
import 'package:flutter/material.dart';

/// 示例 App 定义列表
final List<AppDefinition> kExampleApps = [
  const AppDefinition(
    id: 'pomodoro',
    name: '专注',
    icon: Icons.coffee,
    route: '/pomodoro',
  ),
  const AppDefinition(
    id: 'note',
    name: '笔记',
    icon: Icons.description,
    route: '/note/inbox',
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
