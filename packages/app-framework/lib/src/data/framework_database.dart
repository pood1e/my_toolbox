import 'package:data_biz/data_biz.dart';

import 'launcher/app_usage_entity.dart';
import 'launcher/launcher_dao.dart';

part 'framework_database.g.dart';

@DriftDatabase(tables: [AppUsageEntities], daos: [LauncherDao])
class FrameworkDatabase extends _$FrameworkDatabase {
  // 构造函数：打开数据库连接
  FrameworkDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
