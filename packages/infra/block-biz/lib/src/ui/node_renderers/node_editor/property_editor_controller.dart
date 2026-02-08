import 'dart:async';

import 'package:app_core/di.dart';

import '../../../domain/property.dart';
import '../../../domain/property_config.dart';
import '../../../domain/type_descriptor.dart';
import '../../../repository/property_config_repository.dart';
import '../../../supports/property_def_registry.dart';
import 'property_editor_descriptor.dart';
import 'property_editor_registry.dart';
import 'property_editor_state.dart';

part 'property_editor_controller.g.dart';

@riverpod
class PropertyEditorController<T> extends _$PropertyEditorController<T> {
  late final PropertyEditorDescriptor<T> _descriptor;
  late final ConfigConverter<T> _converter;
  Timer? _debounceTimer;

  @override
  Stream<PropertyEditorState<T>> build(PropertyKey key) async* {
    _descriptor =
        ref.read(propertyEditorDescriptorProvider(key.defId))
            as PropertyEditorDescriptor<T>;
    _converter =
        ref
                .read(propertyDescriptorProvider(key.defId))
                .typeDescriptor
                .configConverter
            as ConfigConverter<T>;

    final repo = await ref.watch(propertyConfigRepoProvider.future);

    PropertyEditorState<T>? currentState;

    // 监听 Repo 的实时数据流
    await for (final remoteValue
        in repo
            .watchConfig(key)
            .map((config) => _converter.decode(config.configs))) {
      if (currentState == null) {
        // --- 1. 初始状态 ---
        currentState = PropertyEditorState<T>(
          current: remoteValue,
          remote: remoteValue,
        );
      } else {
        // --- 2. 后续更新 (来自 Sync) ---
        if (currentState.isDirty) {
          // A. 冲突！用户正在编辑，但远程数据变了
          // 策略：保留用户的草稿 (current)，更新远程基准 (remote)，并标记为 Stale
          currentState = currentState.copyWith(
            remote: remoteValue,
            isStale: true,
          );
        } else {
          // B. 正常同步。用户没有未保存的修改
          // 策略：直接更新草稿和远程基准，保持一致
          currentState = currentState.copyWith(
            current: remoteValue,
            remote: remoteValue,
            isStale: false, // 冲突已解决
            validationError: null, // 假设远程数据总是合法的
          );
        }
      }
      yield currentState;
    }
  }

  /// [UI 调用] 更新草稿
  void updateDraft(T newDraft, {SavePolicy? policyOverride}) {
    final oldState = state.value;
    if (oldState == null) return;

    String? errorMsg;
    final rawValidator = (_descriptor as dynamic).validator;
    if (rawValidator != null) {
      try {
        errorMsg = rawValidator(newDraft);
      } catch (e) {
        errorMsg = 'Type mismatch: ${e.toString()}';
      }
    }

    // 2. 乐观更新内存状态
    state = AsyncValue.data(
      oldState.copyWith(current: newDraft, validationError: errorMsg),
    );

    // 3. 清理旧的防抖计时器
    _debounceTimer?.cancel();

    // 如果校验失败，则**绝不**触发任何保存逻辑
    if (errorMsg != null) {
      return;
    }

    // 4. 根据策略决定是否自动保存
    final policy = policyOverride ?? _descriptor.savePolicy;
    if (policy == SavePolicy.immediate) {
      save();
    } else if (policy == SavePolicy.debounce) {
      _debounceTimer = Timer(const Duration(milliseconds: 800), save);
    }
  }

  /// [UI 调用] 放弃修改 (Cancel 按钮)
  void cancelChanges() {
    final oldState = state.value;
    if (oldState == null) return;

    // 将草稿 (current) 回滚到最新的远程基准 (remote)
    // 这样做同时清除了 isDirty 和 isStale 状态
    state = AsyncValue.data(
      oldState.copyWith(
        current: oldState.remote,
        isStale: false,
        validationError: null,
      ),
    );
    _debounceTimer?.cancel();
  }

  /// [UI 调用] 保存修改 (Save 按钮 或 自动触发)
  Future<void> save() async {
    final currentState = state.value;
    if (currentState == null || !currentState.canSave) {
      return; // 如果状态不允许保存，直接返回
    }

    state = AsyncValue.data(currentState.copyWith(isSaving: true));

    try {
      final repo = await ref.read(propertyConfigRepoProvider.future);

      await repo.fullUpdate(
        PropertyConfig(
          key: key,
          configs: _converter.encode(currentState.current),
        ),
      );

      // 保存成功后，乐观地更新状态。
      // 新的 remote 基准就是我们刚刚提交的 current 值。
      // isDirty 和 isStale 状态也随之解除。
      state = AsyncValue.data(
        currentState.copyWith(
          isSaving: false,
          remote: currentState.current,
          isStale: false,
        ),
      );
    } catch (e) {
      // 保存失败
      state = AsyncValue.data(
        currentState.copyWith(
          isSaving: false,
          // 可以将保存错误也显示在 validationError 字段
          validationError: 'Failed to save: ${e.toString()}',
        ),
      );
    }
  }
}
