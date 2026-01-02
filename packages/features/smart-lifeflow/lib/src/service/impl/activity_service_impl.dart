import '../../domain/reality_models.dart';
import '../../repository/reality_repositories.dart';
import '../reality_services.dart';

/// Activity (行为分类) 业务逻辑实现
/// 职责:
/// 1. 提供 UI 需要的 Activity 数据流。
/// 2. 处理创建、更新、删除 Activity 的业务规则。
class ActivityServiceImpl implements ActivityService {
  final ActivityRepository _activityRepo;

  ActivityServiceImpl({required ActivityRepository activityRepo})
    : _activityRepo = activityRepo;

  // ===========================================================================
  // 1. 数据查询
  // ===========================================================================

  @override
  Stream<List<Activity>> watchAllActivities() {
    // 直接将 Repository 的数据流透传给上层。
    // Service 在这里没有添加额外的业务逻辑（如过滤、排序），
    // 因为 Repository 已经处理好了。
    return _activityRepo.watchAll();
  }

  @override
  Future<Activity?> getActivityById(String id) {
    // 直接透传查询。
    return _activityRepo.getById(id);
  }

  // ===========================================================================
  // 2. 配置管理
  // ===========================================================================

  @override
  Future<String> createNewActivity({
    required String name,
    String? icon,
    String? colorHex,
  }) {
    // 业务规则: 校验输入
    if (name.trim().isEmpty) {
      throw ArgumentError('Activity name cannot be empty.');
    }

    // 业务规则: (未来可以扩展) 检查名称是否重复
    // final existing = await _activityRepo.findByName(name.trim());
    // if (existing != null) {
    //   throw Exception('Activity with this name already exists.');
    // }

    // 调用 Repository 执行创建
    return _activityRepo.createActivity(
      name: name.trim(),
      icon: icon,
      colorHex: colorHex,
    );
  }

  @override
  Future<void> updateActivityDetails(Activity activity) {
    // 业务规则: 校验输入
    if (activity.name.trim().isEmpty) {
      throw ArgumentError('Activity name cannot be empty.');
    }

    // 调用 Repository 执行更新
    // Repository 的 update 方法会自动处理 updatedAt 和 isDirty 标记
    return _activityRepo.update(activity);
  }

  @override
  Future<void> deleteActivity(String activityId) {
    // 业务规则: (未来可以扩展)
    // 1. 检查此 Activity 是否正在被一个进行中的 Log 使用，如果是则阻止删除。
    // 2. 检查是否有 Task 将此 Activity 设为默认，如果是则将其置为 null。

    // MVP 阶段: 直接调用软删除。
    // 数据库的外键 `ON DELETE CASCADE` 会自动处理 ActivityShortcut 的物理删除。
    // 历史的 ActivityLog 记录会保留对这个 (已软删除的) activityId 的引用，这是正确的。
    return _activityRepo.delete(activityId);
  }
}
