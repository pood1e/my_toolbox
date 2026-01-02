import '../domain/reality_models.dart';

/// Activity (行为分类) 相关业务逻辑服务接口
/// 它的职责是管理 Activity 字典本身
abstract class ActivityService {

  // ===========================================================================
  // 1. 数据查询
  // ===========================================================================

  /// 获取所有可管理的活动列表 (用于设置页面)
  Stream<List<Activity>> watchAllActivities();

  /// 获取单个活动详情
  Future<Activity?> getActivityById(String id);

  // ===========================================================================
  // 2. 配置管理
  // ===========================================================================

  /// 创建一个新的活动分类
  Future<String> createNewActivity({
    required String name,
    String? icon,
    String? colorHex,
  });

  /// 更新活动分类的详情 (名称、图标等)
  Future<void> updateActivityDetails(Activity activity);

  /// 删除一个活动分类
  Future<void> deleteActivity(String activityId);
}