abstract class ServerTimeService {
  /// 核心方法：获取当前时间
  DateTime get now;

  /// 获取毫秒时间戳
  int get nowMs;

  /// 校准
  Future<void> calibrate();
}
