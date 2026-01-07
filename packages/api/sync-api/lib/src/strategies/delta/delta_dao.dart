import 'delta_payload.dart';

/// 定义 Delta 策略必须实现的底层操作接口
abstract class DeltaOpInterface<E> {
  // --- 状态检查 ---
  /// 检查表中是否有未同步或已锁定的数据
  Future<DeltaStateSnapshot> checkState();

  // --- 状态流转 (SQL 逻辑) ---
  /// 核心逻辑：将 unsync 字段累加到 locked 字段，并清零 unsync
  /// 例如: UPDATE table SET locked = locked + unsync, unsync = 0 WHERE unsync > 0
  Future<void> moveUnsyncToLocked();

  /// 核心逻辑：清空 locked 字段
  /// 例如: UPDATE table SET locked = 0 WHERE locked > 0
  Future<void> clearLocked();

  // --- 数据获取 ---
  /// 获取所有 locked > 0 的数据用于发送
  Future<List<E>> getLockedItems();
}
