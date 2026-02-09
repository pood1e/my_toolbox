// File: ui/node_renderers/node_editor/property_editor_controller.dart

import 'dart:async';

import 'package:app_core/di.dart';

import '../../../domain/property.dart';
import '../../../domain/property_config.dart';
import '../../../repository/property_config_repository.dart';
import 'property_editor_descriptor.dart';
import 'property_editor_state.dart';

part 'property_editor_controller.g.dart';

@riverpod
class PropertyEditorController extends _$PropertyEditorController {
  Timer? _debounceTimer;

  @override
  Stream<PropertyEditorState> build(PropertyKey key) async* {
    final repo = await ref.watch(propertyConfigRepoProvider.future);

    // 监听远程变更
    await for (final remoteConfig in repo.watchConfig(key)) {
      final current = state.value;

      if (current == null) {
        // 初始化
        yield PropertyEditorState(remote: remoteConfig, draft: remoteConfig);
      } else if (!current.isDirty) {
        // 如果当前没有未保存的草稿，自动跟进远程变更
        yield current.copyWith(remote: remoteConfig, draft: remoteConfig);
      } else {
        // 如果有冲突（用户正在改，远程变了），通常保留用户的 Draft，更新 Remote 基准
        // 并可以在 UI 提示 "Someone else edited this"
        yield current.copyWith(remote: remoteConfig);
      }
    }
  }

  /// 切换模式 (Mode Switch)
  /// 这是一个结构性变更，通常立即保存
  Future<void> switchMode(EditorModeSpec spec) async {
    final current = state.value;
    if (current == null) return;

    // 1. 生成新模式的默认配置
    final newConfig = spec.createDefaultConfig(key);

    // 2. 立即更新 Draft 并保存
    // (结构性变更通常不防抖，防止 UI 渲染错误的编辑器)
    state = AsyncValue.data(current.copyWith(draft: newConfig));
    await _performSave(newConfig);
  }

  /// 更新 Draft (用户输入)
  /// 这是一个值变更，通常防抖保存
  void updateDraft(PropertyConfig newDraft) {
    final current = state.value;
    if (current == null) return;

    // 1. 乐观更新
    state = AsyncValue.data(current.copyWith(draft: newDraft));

    // 2. 防抖保存
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSave(newDraft);
    });
  }

  Future<void> _performSave(PropertyConfig configToSave) async {
    state = AsyncValue.data(state.value!.copyWith(isSaving: true));
    try {
      final repo = await ref.read(propertyConfigRepoProvider.future);
      await repo.fullUpdate(configToSave); // Repo 内部会做 Diff

      // 保存成功后，Remote 追上 Draft
      // 注意：这里不需要手动设置 state，因为 Repo 的 update 会触发 watchConfig 的流更新
      // 我们依赖 Stream 回调来更新 remote 字段
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(error: e.toString()));
    } finally {
      state = AsyncValue.data(state.value!.copyWith(isSaving: false));
    }
  }
}
