import 'package:flutter/material.dart';

/// 预设颜色池 (灵感来自 Material 3 & Apple Health)
class ActivityColors {
  static const List<String> presets = [
    'F44336', // Red (High Energy)
    'E91E63', // Pink
    '9C27B0', // Purple
    '673AB7', // Deep Purple (Sleep/Deep work)
    '2196F3', // Blue (Study/Focus)
    '00BCD4', // Cyan
    '009688', // Teal
    '4CAF50', // Green (Sport/Health)
    'FFEB3B', // Yellow
    'FF9800', // Orange
    '795548', // Brown
    '607D8B', // Blue Grey (Commute)
  ];

  static Color fromHex(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    return Color(int.parse('0xFF$hex'));
  }
}

/// 预设图标池 (使用 Emoji 降低资源依赖，且表现力强)
class ActivityIcons {
  static const List<String> presets = [
    '💼', '📚', '💻', '🎨', // Work / Creation
    '🏃', '🧘', '🏋️', '🚴', // Sport
    '🛌', '🚿', '🍽️', '☕', // Life / Basic
    '🎮', '🎬', '🎵', '✈️', // Fun
    '🚗', '🚇', '🏠', '🛒', // Commute / Chores
  ];
}