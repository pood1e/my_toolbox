import 'package:common_ui/style.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme_settings.dart';

class AppTheme {
  /// 创建 ThemeData 的工厂方法
  ///
  /// [settings]: 用户配置（包含自定义 seedColor）
  /// [isDark]: 当前是否是深色模式
  /// [systemScheme]: 从 dynamic_color 获取的系统动态配色（如果在 Android 12+ 且用户开启了跟随系统，这里会有值）
  static ThemeData create({
    required ThemeSettings settings,
    required bool isDark,
    ColorScheme? systemScheme,
  }) {
    // 1. 定义基础配置
    // 为了保持 UI 的精致感，我们添加一些混合(Blend)效果
    // 这会让 Surface (背景) 微微带有主色的色调，而不是纯灰/纯黑
    const int blendLevel = 10;
    const FlexSurfaceMode surfaceMode =
        FlexSurfaceMode.levelSurfacesLowScaffold;

    ThemeData themeData;

    if (systemScheme != null) {
      // ------------------------------------------------------------
      // 分支 A: 使用系统动态配色 (Dynamic Color)
      // ------------------------------------------------------------
      // FlexThemeData 可以直接接受 colorScheme 参数
      if (isDark) {
        themeData = FlexThemeData.dark(
          colorScheme: systemScheme,
          // 直接使用系统传递的 Scheme
          useMaterial3: true,
          surfaceMode: surfaceMode,
          blendLevel: blendLevel,
          // 修复系统色在某些组件上可能对比度不足的问题
          appBarStyle: FlexAppBarStyle.scaffoldBackground,
        );
      } else {
        themeData = FlexThemeData.light(
          colorScheme: systemScheme,
          useMaterial3: true,
          surfaceMode: surfaceMode,
          blendLevel: blendLevel,
          appBarStyle: FlexAppBarStyle.scaffoldBackground,
        );
      }
    } else {
      // ------------------------------------------------------------
      // 分支 B: 使用用户自定义的种子颜色 (Custom Seed Color)
      // ------------------------------------------------------------
      final seedColor = Color(settings.seedColorValue);

      // 使用 FlexSchemeColor 从单色生成完整色板
      final schemeColors = FlexSchemeColor.from(
        primary: seedColor,
        // 可以根据需要配置 secondary，或者让算法自动生成
        brightness: isDark ? Brightness.dark : Brightness.light,
      );

      if (isDark) {
        themeData = FlexThemeData.dark(
          colors: schemeColors,
          useMaterial3: true,
          surfaceMode: surfaceMode,
          blendLevel: blendLevel,
          // 预设一些子组件样式，让它看起来更现代
          subThemesData: const FlexSubThemesData(
            blendOnLevel: 20,
            useMaterial3Typography: true, // 优化文本对比度
            inputDecoratorBorderType: FlexInputBorderType.outline, // 输入框样式
            inputDecoratorRadius: 12.0,
          ),
        );
      } else {
        themeData = FlexThemeData.light(
          colors: schemeColors,
          useMaterial3: true,
          surfaceMode: surfaceMode,
          blendLevel: blendLevel,
          subThemesData: const FlexSubThemesData(
            blendOnLevel: 10,
            blendOnColors: false,
            useMaterial3Typography: true,
            inputDecoratorBorderType: FlexInputBorderType.outline,
            inputDecoratorRadius: 12.0,
          ),
        );
      }
    }

    // 2. 应用字体 (Typography)
    // 使用 GoogleFonts 统一应用到所有 TextStyles
    // Noto Sans 对多语言支持较好
    final textTheme = GoogleFonts.notoSansTextTheme(themeData.textTheme);

    // 3. 注入扩展 (Theme Extensions) & 返回最终 Theme
    return themeData.copyWith(
      textTheme: textTheme,

      // 这里注入我们在 custom_colors.dart 定义的扩展
      extensions: [
        isDark ? AppStatusColors.dark : AppStatusColors.light,

        // 如果你将来加了手写字体扩展，也是放在这里
        // isDark ? ContentTypography.dark : ContentTypography.light,
      ],
    );
  }
}
