import 'package:app_core/http.dart';
import 'package:app_core/logger.dart';
import 'package:app_core/object.dart';
import 'package:network_api/network_api.dart';
import 'package:system_clock/system_clock.dart';

import '../../data/server_time_storage.dart';
import '../../utils/boot_id_util.dart';

class ServerTimeServiceImpl implements ServerTimeService {
  final ServerTimeStorage _storage;
  final String? _baseurl;
  bool _hasSetBootId = false;

  int? _anchor;

  ServerTimeServiceImpl({
    required ServerTimeStorage storage,
    required String? baseurl,
  }) : _storage = storage,
       _baseurl = baseurl;

  Future<void> tryRestoreAnchor() async {
    final bootId = await BootIdUtil.getBootId();
    final savedBootId = await _storage.getBootId();
    final savedAnchor = await _storage.getAnchor();
    if (bootId != null && savedBootId == bootId && savedAnchor != 0) {
      _anchor = savedAnchor;
      logger.i('✅ [TimeService] 冷启动恢复成功，BootID 匹配: $bootId');
    } else {
      logger.w('⚠️ [TimeService] 旧 Anchor 失效');
      await calibrate();
    }
  }

  /// 获取当前准确时间
  @override
  DateTime get now {
    return DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true);
  }

  /// 网络校准
  @override
  Future<void> calibrate() async {
    if (_baseurl == null) {
      return;
    }
    final dio = Dio();
    try {
      final startTick = SystemClock.uptime().inMilliseconds;
      final response = await dio.get('$_baseurl/time');
      final result = R<int>.fromJson(response.data, (t) => t as int);
      final int serverTimeMs = result.data!;

      final endTick = SystemClock.uptime().inMilliseconds;
      final int latency = (endTick - startTick) ~/ 2;

      // 准确的 ServerTime
      final accurateServerTimeMs = serverTimeMs + latency;

      // 计算 Anchor = ServerTime - Uptime
      // 注意：这里的 Uptime 必须是收到响应时的 Uptime
      final currentUptime = endTick;
      _anchor = accurateServerTimeMs - currentUptime;

      _storage.saveAnchor(_anchor!);
      logger.i('✅ 时间校准完成 (持久化). latency:$latency, Anchor: $_anchor');
      if (!_hasSetBootId) {
        final bootId = await BootIdUtil.getBootId();
        if (bootId != null) {
          await _storage.saveBootId(bootId);
          logger.i('✅ 记录BootId: $bootId');
        }
        _hasSetBootId = true;
      }
    } catch (e) {
      logger.i('❌ 校准失败: $e');
    } finally {
      dio.close();
    }
  }

  @override
  int get nowMs {
    if (_anchor == null) {
      return DateTime.now().millisecondsSinceEpoch;
    }

    final uptimeMs = SystemClock.uptime().inMilliseconds;
    return _anchor! + uptimeMs;
  }
}
