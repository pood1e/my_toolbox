import 'package:flutter/material.dart';

/// 统一的间距定义
class AppSpacings {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

  // 页面默认边距
  static const double page = xl;
}

/// 统一的圆角定义
class AppRadius {
  static const double s = 4.0;
  static const double m = 8.0;
  static const double l = 12.0;
  static const double xl = 16.0;

  static const Radius circleM = Radius.circular(m);
  static const Radius circleL = Radius.circular(l);
  static BorderRadius card = BorderRadius.circular(l);
  static BorderRadius input = BorderRadius.circular(m);
}

/// 统一的间隔组件 (减少写 SizedBox 的重复代码)
class Gaps {
  /// 水平间隔
  static const Widget h4 = SizedBox(width: AppSpacings.xs);
  static const Widget h8 = SizedBox(width: AppSpacings.s);
  static const Widget h12 = SizedBox(width: AppSpacings.m);
  static const Widget h16 = SizedBox(width: AppSpacings.l);

  /// 垂直间隔
  static const Widget v4 = SizedBox(height: AppSpacings.xs);
  static const Widget v8 = SizedBox(height: AppSpacings.s);
  static const Widget v12 = SizedBox(height: AppSpacings.m);
  static const Widget v16 = SizedBox(height: AppSpacings.l);
  static const Widget v24 = SizedBox(height: AppSpacings.xl);
}

/// 统一的输入框装饰器风格
class AppInputStyles {
  static InputDecoration outline({
    required String label,
    IconData? prefixIcon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      border: OutlineInputBorder(borderRadius: AppRadius.input),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: const BorderSide(color: Colors.grey), // 可结合 Theme 颜色
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacings.m,
        vertical: AppSpacings.m,
      ),
      isDense: true,
    );
  }
}
