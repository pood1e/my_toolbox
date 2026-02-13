import 'package:app_core/di.dart';

import '../domain/property.dart';
import '../domain/property_config.dart';
import '../registry/config_spec_registry.dart';
import '../registry/property_descriptor_registry.dart';
import '../repository/property_config_repository.dart';
import '../repository/property_repository.dart';
import 'property_draft_state.dart';

part 'property_draft_controller.g.dart';

/// 通用属性草稿控制器
@riverpod
class PropertyDraftController extends _$PropertyDraftController {
  final Map<String, PropertyConfigBody> _specDraftMap = {};

  @override
  Future<PropertyDraftState> build(PropertyKey key) async {
    final repo = await ref.watch(propertyConfigRepoProvider.future);

    // 1. 获取初始数据 (用于 build 方法的首次返回)
    // 假设 repo.watchConfig 是广播流或可以多次监听，
    // 如果是单订阅流，建议 repo 提供一个 .get(key) 方法来获取初始值。
    final initialConfig = await repo.getConfig(key);

    // 2. 设置长期监听
    final sub = repo.watchConfig(key).listen((remoteConfig) {
      if (remoteConfig == null) return;

      // 获取当前最新的状态
      final current = state.value;

      // 如果当前状态还没初始化完成（极少见），或者数据为空，直接覆盖
      if (current == null) {
        state = AsyncValue.data(
          PropertyDraftState(
            remoteSpec: remoteConfig.spec,
            currentSpec: remoteConfig.spec,
            remote: remoteConfig.body,
            draft: remoteConfig.body,
          ),
        );
        return;
      }

      // 3. 远程更新处理逻辑 (合并逻辑)
      // 如果用户正在聚焦编辑(isFocused) 或 草稿已脏(isDirty)，则不覆盖用户的草稿，只更新基准值
      if (current.isDirty || current.isFocused) {
        // 避免不必要的 state 更新重绘
        if (current.remote != remoteConfig.body ||
            current.remoteSpec != remoteConfig.spec) {
          state = AsyncValue.data(
            current.copyWith(
              remoteSpec: remoteConfig.spec,
              remote: remoteConfig.body,
            ),
          );
        }
      } else {
        // 自动同步远程值到草稿
        // 同样检查是否真的变了，避免死循环或多余重绘
        if (current.remote != remoteConfig.body ||
            current.remoteSpec != remoteConfig.spec) {
          state = AsyncValue.data(
            current.copyWith(
              remoteSpec: remoteConfig.spec,
              remote: remoteConfig.body,
              currentSpec: remoteConfig.spec,
              draft: remoteConfig.body,
            ),
          );
        }
      }
    });

    // 4. 关键：在 Provider 销毁时取消监听，防止内存泄漏
    ref.onDispose(sub.cancel);

    // 5. 返回初始状态
    if (initialConfig == null) {
      // 根据业务需求处理，这里抛出异常或返回空对象
      throw Exception('Config not found for key: $key');
    }

    return PropertyDraftState(
      remoteSpec: initialConfig.spec,
      currentSpec: initialConfig.spec,
      remote: initialConfig.body,
      draft: initialConfig.body,
    );
  }

  void switchSpec(String spec) {
    final current = state.value;
    if (current == null) return;
    if (current.currentSpec == spec) return;
    // 暂存当前spec的草稿
    _specDraftMap.putIfAbsent(current.currentSpec, () => current.draft);
    // 查看是否有草稿
    final existDraft = _specDraftMap[spec];
    if (existDraft != null) {
      saveSpecAndValue(spec, existDraft);
      return;
    }
    // 默认构建
    final specDesc = ref.read(configSpecDescriptorProvider(spec))!;
    final defaultFunc = specDesc.createDefault;
    if (defaultFunc == null) {
      throw Exception('not found default fun');
    }
    final body = defaultFunc();
    saveSpecAndValue(spec, body);
  }

  String? _validate(PropertyConfigBody body) {
    switch (body) {
      case SingleStaticPropertyConfig(:final processor):
        return processor.component.validate(processor.raw);
      case SingleRefPropertyConfig(:final transformer):
        if (transformer.target == null) {
          return 'target is empty';
        }
        return transformer.component.validate(transformer.raw);
      case MultiStaticPropertyConfig():
        return null;
      case MultiRefPropertyConfig():
        // TODO: Handle this case.
        throw UnimplementedError();
      case HybridPropertyConfig():
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  /// 更新草稿 (用户输入)
  void updateDraft(PropertyConfigBody newDraft) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(
      current.copyWith(draft: newDraft, error: _validate(newDraft)),
    );
  }

  void saveSpecAndValue(String spec, PropertyConfigBody newDraft) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(
      current.copyWith(
        currentSpec: spec,
        draft: newDraft,
        error: _validate(newDraft),
      ),
    );
  }

  /// 设置焦点状态 (用于控制是否自动同步 Remote)
  void setFocus(bool isFocused) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(isFocused: isFocused));
  }

  /// 撤销更改 (重置为 Remote)
  void undo() {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(draft: current.remote));
  }

  Future<void> performSave() async {
    final current = state.value;
    if (current == null) return;

    state = AsyncValue.data(current.copyWith(isSaving: true));
    try {
      final repo = await ref.read(propertyConfigRepoProvider.future);
      await repo.fullUpdate(
        PropertyConfig(
          key: key,
          spec: current.currentSpec,
          body: current.draft,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(current.copyWith(error: e.toString()));
    } finally {
      final newest = state.value;
      if (newest != null) {
        state = AsyncValue.data(newest.copyWith(isSaving: false));
      }
    }
  }
}

@riverpod
Stream<Property?> watchProperty(Ref ref, PropertyKey key) async* {
  final descriptor = ref.watch(propertyDescriptorProvider(key.defId));
  final repo = await ref.watch(propertyRepositoryProvider.future);
  yield* repo.watchSingle(key, descriptor!.dateType.definition.storageType);
}
