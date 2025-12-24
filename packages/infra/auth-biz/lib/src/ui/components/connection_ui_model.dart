import '../../../auth_biz.dart';
import 'package:flutter/material.dart';

extension ConnectionAvailabilityUI on ConnectionAvailability {
  /// 是否显示 Banner
  bool get shouldShowBanner {
    switch (this) {
      case ConnectionAvailability.active:
      case ConnectionAvailability.guest:
        return false;
      case ConnectionAvailability.expired:
      case ConnectionAvailability.offline:
      case ConnectionAvailability.verifying:
        return true;
    }
  }

  /// 是否允许手动关闭
  bool get isDismissible => this != ConnectionAvailability.verifying;

  /// 背景色 (使用更柔和的色调)
  Color get backgroundColor {
    switch (this) {
      case ConnectionAvailability.expired:
        return const Color(0xFFFFF3CD); // 柔和橙
      case ConnectionAvailability.offline:
        return const Color(0xFFF8D7DA); // 柔和红
      case ConnectionAvailability.verifying:
        return const Color(0xFFCCE5FF); // 柔和蓝
      default:
        return Colors.white;
    }
  }

  /// 边框/文字/图标的主色调
  Color get accentColor {
    switch (this) {
      case ConnectionAvailability.expired:
        return const Color(0xFF856404); // 深橙褐
      case ConnectionAvailability.offline:
        return const Color(0xFF721C24); // 深红
      case ConnectionAvailability.verifying:
        return const Color(0xFF004085); // 深蓝
      default:
        return Colors.black;
    }
  }

  Widget get icon {
    switch (this) {
      case ConnectionAvailability.expired:
        return Icon(Icons.lock_clock_outlined, color: accentColor);
      case ConnectionAvailability.offline:
        return Icon(Icons.wifi_off_rounded, color: accentColor);
      case ConnectionAvailability.verifying:
        return SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: accentColor),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String get message {
    switch (this) {
      case ConnectionAvailability.expired:
        return '登录状态已过期';
      case ConnectionAvailability.offline:
        return '网络连接已断开';
      case ConnectionAvailability.verifying:
        return '正在连接服务器...';
      default:
        return '';
    }
  }
}
