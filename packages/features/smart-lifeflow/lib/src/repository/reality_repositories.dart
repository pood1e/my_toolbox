import 'package:framework_api/framework_api.dart';

import '../data/lifeflow_database.dart';
import '../domain/reality_models.dart';

/// Activity (行为分类) 的数据仓库接口
/// 负责 Activity 的增删改查

abstract class ActivityRepository
    implements CoreSyncRepository<Activity, ActivitiesCompanion> {
  /// 监听所有活动 (未删除)
  /// 用于 UI 列表展示，例如 "设置 -> 管理我的活动"
  Stream<List<Activity>> watchAll();

  /// 创建一个新的活动
  /// 这是 Activity 特有的创建方法，因为它需要 'name' 等业务字段
  Future<String> createActivity({
    required String name,
    String? icon,
    String? colorHex,
  });
}