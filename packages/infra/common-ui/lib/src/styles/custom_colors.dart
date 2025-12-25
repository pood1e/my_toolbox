import 'package:flutter/material.dart';

@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  final Color? success;
  final Color? warning;
  final Color? expired;

  const AppStatusColors({this.success, this.warning, this.expired});

  @override
  AppStatusColors copyWith({Color? success, Color? warning, Color? expired}) {
    return AppStatusColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      expired: expired ?? this.expired,
    );
  }

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) return this;
    return AppStatusColors(
      success: Color.lerp(success, other.success, t),
      warning: Color.lerp(warning, other.warning, t),
      expired: Color.lerp(expired, other.expired, t),
    );
  }

  // 定义浅色模式下的颜色
  static const light = AppStatusColors(
    success: Color(0xFF2E7D32), // 深绿
    warning: Color(0xFFED6C02), // 深橙
    expired: Color(0xFFD32F2F), // 深红
  );

  // 定义深色模式下的颜色 (通常更柔和，或者饱和度更低)
  static const dark = AppStatusColors(
    success: Color(0xFF66BB6A), // 浅绿
    warning: Color(0xFFFFA726), // 浅橙
    expired: Color(0xFFEF5350), // 浅红
  );
}
