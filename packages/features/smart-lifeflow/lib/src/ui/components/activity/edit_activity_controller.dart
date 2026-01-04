
// 必须添加 part 文件声明，文件名需与当前文件一致
import 'package:app_core/di.dart';
import 'package:app_core/object.dart';

import '../../../domain/reality_models.dart';
import '../../../service/service_providers.dart';
import 'activity_presets.dart';

part 'edit_activity_controller.freezed.dart';
part 'edit_activity_controller.g.dart';

// =============================================================================
// 1. State (使用 Freezed 定义不可变状态)
// =============================================================================
@freezed
abstract class EditActivityState with _$EditActivityState {
  const factory EditActivityState({
    @Default('📝') String selectedIcon,
    // 默认给一个初始颜色，具体逻辑在 Controller build 中处理
    @Default('F44336') String selectedColorHex,
    Activity? initialData,
  }) = _EditActivityState;
}

// =============================================================================
// 2. Controller (使用 Riverpod Generator)
// =============================================================================
@riverpod
class EditActivityController extends _$EditActivityController {

  /// build 方法的参数 (activityId) 会自动变成 Family 的参数
  /// 返回 Future<EditActivityState> 会自动处理 Loading/Error/Data 状态
  @override
  Future<EditActivityState> build(String? activityId) async {
    // 1. 新建模式
    if (activityId == null) {
      return EditActivityState(
        selectedColorHex: ActivityColors.presets.first,
      );
    }

    // 2. 编辑模式：异步加载数据
    final service = await ref.watch(activityServiceProvider.future);
    final activity = await service.getActivityById(activityId);

    // 如果找不到数据 (极少情况)，返回默认
    if (activity == null) {
      return EditActivityState(selectedColorHex: ActivityColors.presets.first);
    }

    // 3. 返回加载后的数据
    return EditActivityState(
      initialData: activity,
      selectedIcon: activity.icon ?? '📝',
      selectedColorHex: activity.colorHex ?? ActivityColors.presets.first,
    );
  }

  // --- 状态更新方法 (同步更新 AsyncData) ---

  void setIcon(String icon) {
    // 只有当数据加载完成(state.value != null)时才允许修改
    if (state.hasValue) {
      state = AsyncData(state.value!.copyWith(selectedIcon: icon));
    }
  }

  void setColor(String hex) {
    if (state.hasValue) {
      state = AsyncData(state.value!.copyWith(selectedColorHex: hex));
    }
  }

  // --- 业务逻辑方法 ---

  Future<void> save(String name) async {
    // 确保当前状态已加载
    final currentState = state.value;
    if (currentState == null) return;

    final service = await ref.read(activityServiceProvider.future);

    if (activityId != null && currentState.initialData != null) {
      // Update
      final updated = currentState.initialData!.copyWith(
        name: name,
        icon: currentState.selectedIcon,
        colorHex: currentState.selectedColorHex,
      );
      await service.updateActivityDetails(updated);
    } else {
      // Create
      await service.createNewActivity(
        name: name,
        icon: currentState.selectedIcon,
        colorHex: currentState.selectedColorHex,
      );
    }
  }

  Future<void> delete() async {
    if (activityId == null) return;
    final service = await ref.read(activityServiceProvider.future);
    await service.deleteActivity(activityId!);
  }
}