import 'dart:async';

import 'package:app_core/di.dart';
import 'package:app_core/logger.dart';

import '../../../config/config_service.dart';
import '../../../meta/property_meta_service.dart';
import '../../../meta/registry/text_meta.dart';

part 'text_editor.g.dart';

@riverpod
class TextEditorController extends _$TextEditorController {
  // 1. 防抖计时器
  Timer? _debounceTimer;

  // 2. 暂存用户输入的最新文本 (Pending State)
  // 如果为 null，说明没有待写入的变更
  String? _pendingText;

  // 3. 记录来自数据库的最新快照 (Snapshot)
  // 用于在 update 时作为旧值传入，用于计算 Diff
  TextConfig? _lastSavedConfig;

  @override
  Future<TextConfig> build(PropertyId propertyId) async {
    // 注册销毁回调：当 UI 关闭导致 Provider 销毁时触发
    ref.onDispose(() {
      _debounceTimer?.cancel();
      // 如果还有未写入的文本，在销毁前强制写入
      if (_pendingText != null) {
        _flush(_pendingText!);
      }
    });

    final config = await ref.watch(
      watchPropertyConfigProvider(propertyId).future,
    );
    _lastSavedConfig = config;
    return config;
  }

  /// 用户输入时调用此方法 (UI 层调用)
  void updateText(String newText) {
    // 1. 取消上一次的计时器
    _debounceTimer?.cancel();

    // 2. 更新待写入的文本
    _pendingText = newText;

    // 3. 启动新的计时器 (例如 500ms 防抖)
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      // 计时结束，执行写入
      _flush(newText);
    });
  }

  /// 内部方法：执行真正的数据库写入
  Future<void> _flush(String textToWrite) async {
    // 标记 pending 为 null，表示变更已提交
    _pendingText = null;

    // 获取 Service (这里使用 read，因为 flush 可能在 dispose 时调用，此时 watch 不安全或已失效)
    // 注意：ref.read 在 dispose 回调中是允许的，只要用来获取保持活跃的 Provider (Service 通常是 KeepAlive 的)
    final service = await ref.read(configServiceProvider.future);

    // 如果还没获取到初始数据，或者数据为空，无法进行 update (视业务逻辑而定)
    // 这里假设 _lastSavedConfig 在 build 之后至少会有一次值
    final snapshot = _lastSavedConfig;

    if (snapshot == null) return;

    try {
      // 执行更新
      await service.update(propertyId, snapshot, TextConfig(text: textToWrite));
    } catch (e) {
      // 错误处理：如果写入失败，可能需要恢复 pendingText 或者通知 UI
      // 在 dispose 场景下，这里只能打印日志
      logger.e('Auto-save failed: $e');
    }
  }

  Future<void> deleteProperty() async {
    _debounceTimer?.cancel(); // 删除前取消所有挂起的更新
    _pendingText = null;
    final service = await ref.read(configServiceProvider.future);
    await service.delete(propertyId);
  }
}
