import 'package:app_core/object.dart';
import 'package:flutter/material.dart';

part 'theme_settings.freezed.dart';
part 'theme_settings.g.dart';

@freezed
abstract class ThemeSettings with _$ThemeSettings {
  const factory ThemeSettings({
    /// 亮暗模式: System / Light / Dark
    @Default(ThemeMode.system) ThemeMode themeMode,

    /// 是否跟随系统取色 (Android 12+ 动态取色)
    /// 默认为 true
    @Default(true) bool followSystemColor,

    /// 如果不跟随系统，用户自定义的种子颜色值
    /// 默认为 M3 标准紫 (0xFF6750A4) 或你的品牌色
    @Default(0xFF6750A4) int seedColorValue,
  }) = _ThemeSettings;

  factory ThemeSettings.fromJson(Map<String, dynamic> json) =>
      _$ThemeSettingsFromJson(json);
}
