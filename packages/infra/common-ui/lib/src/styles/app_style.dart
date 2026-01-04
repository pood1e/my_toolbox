import 'package:flutter/material.dart';

// =============================================================================
// 1. 基础度量 (Metrics)
// =============================================================================

/// 统一间距定义 (Space System)
/// 使用 T-shirt Sizing (xs, s, m...) 替代硬编码数字
class AppSpacings {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

  // 语义化间距
  static const double page = xl; // 页面默认内边距 (24.0)
  static const double card = l; // 卡片内部内边距 (16.0)
}

/// 组件特定尺寸 (Component Sizes)
class AppSizes {
  // 图标容器尺寸 (用于 Activity 图标背景)
  static const double iconBoxSmall = 42.0;
  static const double iconBoxMedium = 48.0;
  static const double iconBoxLarge = 56.0;
}

/// 统一圆角定义 (Radius System)
class AppRadius {
  static const double s = 4.0;
  static const double m = 8.0;
  static const double l = 12.0;
  static const double xl = 16.0;

  // 常用 Radius 对象
  static const Radius circleM = Radius.circular(m);
  static const Radius circleL = Radius.circular(l);

  // 常用 BorderRadius 对象
  static BorderRadius card = BorderRadius.circular(l); // 卡片圆角 (12)
  static BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(xl),
  ); // 底部弹窗圆角 (16)
  static BorderRadius input = BorderRadius.circular(m); // 输入框圆角 (8)
}

/// 透明度/Alpha 定义 (Alpha System)
/// 配合 Color.withValues(alpha: ...) 使用
class AppAlpha {
  static const double low = 0.05; // 极浅背景
  static const double medium = 0.15; // 次级背景/图标背景
  static const double high = 0.5; // 禁用态/辅助文字
  static const double disabled = 0.3;
}

/// 阴影定义
class AppShadows {
  static const double blurRadius = 10.0;
  static const Offset offset = Offset(0, 4);

  /// 生成统一风格的阴影
  static List<BoxShadow> card(ColorScheme colors) => [
    BoxShadow(
      color: colors.shadow.withValues(alpha: AppAlpha.low),
      blurRadius: blurRadius,
      offset: offset,
    ),
  ];
}

/// 动画时长
class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
}

// =============================================================================
// 2. 便捷组件 (Widgets & Styles)
// =============================================================================

/// 统一间隔组件 (Gaps)
/// 减少 SizedBox 重复代码
class Gaps {
  /// 水平间隔
  static const Widget h4 = SizedBox(width: AppSpacings.xs);
  static const Widget h8 = SizedBox(width: AppSpacings.s);
  static const Widget h12 = SizedBox(width: AppSpacings.m);
  static const Widget h16 = SizedBox(width: AppSpacings.l);
  static const Widget h24 = SizedBox(width: AppSpacings.xl);

  /// 垂直间隔
  static const Widget v4 = SizedBox(height: AppSpacings.xs);
  static const Widget v8 = SizedBox(height: AppSpacings.s);
  static const Widget v12 = SizedBox(height: AppSpacings.m);
  static const Widget v16 = SizedBox(height: AppSpacings.l);
  static const Widget v24 = SizedBox(height: AppSpacings.xl);
  static const Widget v32 = SizedBox(height: AppSpacings.xxl);
}

/// 统一输入框风格 (Input Styles)
class AppInputStyles {
  /// 生成大纲风格的 InputDecoration
  /// [context] 用于获取当前主题色 (支持深色模式)
  static InputDecoration outline(
    BuildContext context, {
    required String label,
    IconData? prefixIcon,
    String? hint,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: colorScheme.outline)
          : null,
      filled: true,
      fillColor: colorScheme.surface,
      // 填充背景色

      // 默认边框
      border: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: BorderSide.none, // 平时不显示边框，只显示填充
      ),
      // 启用但在非焦点状态
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: BorderSide.none,
      ),
      // 焦点状态
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      // 错误状态
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: BorderSide(color: colorScheme.error),
      ),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacings.l,
        vertical: AppSpacings.m,
      ),
      isDense: true,
    );
  }
}

// =============================================================================
// 3. 扩展方法 (Extensions)
// =============================================================================

/// 上下文扩展，快速获取主题配置
extension AppThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => theme.textTheme;

  ColorScheme get colorScheme => theme.colorScheme;

  /// 自定义页面背景色 (适配深色模式)
  Color get pageBackground => theme.brightness == Brightness.light
      ? const Color(0xFFF5F7FA) // 浅灰背景
      : const Color(0xFF121212); // 深色背景
}
