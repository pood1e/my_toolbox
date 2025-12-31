import 'package:app_core/core.dart';
import 'package:framework_api/framework_api.dart';

import '../../data/shell_database.dart';
import '../../data/launcher/app_usage_dao.dart';
import '../launcher_service.dart';

class LauncherServiceImpl implements LauncherService {
  final List<AppDefinition> _allApps;
  final AppUsageDao _dao;
  final ServerTimeService _serverTimeService;
  final SyncAction _syncAction;

  LauncherServiceImpl({
    required List<AppDefinition> allApps,
    required AppUsageDao dao,
    required ServerTimeService serverTimeService,
    required SyncAction syncAction,
  }) : _allApps = allApps,
       _dao = dao,
       _serverTimeService = serverTimeService,
       _syncAction = syncAction;

  @override
  Future<void> record(String id) async {
    await _dao.recordUsage(id, _serverTimeService.nowMs);
    await _syncAction('app_usage');
  }

  @override
  Stream<List<AppDefinition>> watchApps() {
    return _dao.watchAllUsage().map((usageList) {
      // 3. 数据合并与排序逻辑
      return _mergeAndSortApps(_allApps, usageList);
    });
  }

  @override
  Future<List<AppDefinition>> search(String text) async {
    final query = text.trim().toLowerCase();
    if (query.isEmpty) {
      // 如果搜索词为空，返回基于当前使用习惯排序的列表
      // 注意：这里需要拿一次当前的数据库快照，否则只能返回默认排序
      // 为了性能和一致性，这里简单返回默认列表或快速获取一次 DB
      try {
        final usageList = await _dao.watchAllUsage().first; // 取一次快照
        return _mergeAndSortApps(_allApps, usageList);
      } catch (e) {
        return _allApps; // 降级处理
      }
    }

    // 简单的内存过滤
    // 实际项目中可能支持拼音搜索等
    return _allApps.where((app) {
      final nameMatches = app.name.toLowerCase().contains(query);
      final idMatches = app.id.toLowerCase().contains(query);
      return nameMatches || idMatches;
    }).toList();
  }

  /// 核心排序算法
  List<AppDefinition> _mergeAndSortApps(
    List<AppDefinition> sourceApps,
    List<AppUsage> usageLogs,
  ) {
    // 1. 构建 usage 查找表 (Module ID -> UsageEntity)
    // 只有有记录的 App 才会在这里
    final usageMap = {for (var log in usageLogs) log.module: log};

    // 2. 复制一份列表准备排序
    final sortedList = List<AppDefinition>.from(sourceApps);

    // 3. 执行排序
    sortedList.sort((a, b) {
      final usageA = usageMap[a.id];
      final usageB = usageMap[b.id];

      // 规则 A: 两个都有使用记录，按时间倒序 (最近使用的排前面)
      if (usageA != null && usageB != null) {
        return usageB.lastUsedAt.compareTo(usageA.lastUsedAt);
      }

      // 规则 B: 只有一个有记录，有记录的排前面
      if (usageA != null) return -1; // A 排前
      if (usageB != null) return 1; // B 排后

      // 规则 C: 都没有记录，保持默认顺序 (或者按名称排序)
      // return a.name.compareTo(b.name);
      return 0; // 保持原有的 _allApps 定义顺序
    });

    return sortedList;
  }
}
