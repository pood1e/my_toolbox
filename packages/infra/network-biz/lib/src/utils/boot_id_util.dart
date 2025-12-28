import 'dart:io';

import 'package:app_core/logger.dart';
import 'package:flutter/services.dart';

class BootIdUtil {
  BootIdUtil._();

  static String? _bootId;
  static bool? _failed;
  static const _channel = MethodChannel('me.pood1e/boot_id');

  static Future<String?> getBootId() async {
    if (_bootId != null) {
      return _bootId;
    }
    if (_failed ?? false) {
      return null;
    }
    try {
      if (Platform.isLinux) {
        // 1. Linux: 直接读文件 (纯 Dart)
        _bootId = await _getLinuxBootId();
      } else if (Platform.isAndroid || Platform.isIOS) {
        // 3. 移动端: 使用 MethodChannel (之前的方案)
        _bootId = await _channel.invokeMethod<String>('getBootId');
      }
      if (_bootId == null) {
        throw Exception('not support platform');
      }
      return _bootId;
    } catch (e) {
      logger.e('error when get boot id', error: e);
      _failed = true;
      return null;
    }
  }

  static Future<String?> _getLinuxBootId() async {
    try {
      final file = File('/proc/sys/kernel/random/boot_id');
      // 检查文件是否存在 (绝大多数 Linux 发行版都支持)
      if (await file.exists()) {
        // 读取内容并去除首尾空白符 (通常末尾有个换行)
        final content = await file.readAsString();
        return content.trim();
      }
    } catch (e) {
      print('❌ 读取 Linux Boot ID 失败: $e');
    }
    return null;
  }
}
