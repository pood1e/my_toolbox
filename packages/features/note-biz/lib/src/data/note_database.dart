import 'package:app_core/di.dart';
import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import '../note_domain.dart';

part 'note_database.g.dart';

@DataClassName('DocumentEntity')
class Documents extends StandardCocTable
    with CreatedAtTableMixin, DeletedAtTableMixin {
  TextColumn get id => text()();

  TextColumn get title => text().withDefault(const Constant(''))();

  TextColumn get content => text().map(const JsonMapConverter())();

  IntColumn get status => intEnum<DocumentStatus>()();

  BoolColumn get isIndexed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column>? get primaryKey => {id};
}

// -----------------------------------------------------------------------------
// 2. 表结构定义
// -----------------------------------------------------------------------------
@DataClassName('BlockEntity')
class Blocks extends Table {
  // 1. 块 ID (Primary Key)
  // 对应 AppFlowy Editor 中 node.id (UUID)
  TextColumn get blockId => text()();

  // 2. 归属文档 ID (Foreign Key)
  // 关联到 Documents 表。onDelete: Cascade 表示删文档自动删这里的所有块
  TextColumn get docId =>
      text().references(Documents, #id, onDelete: KeyAction.cascade)();

  // 3. 块的纯文本内容 (冗余字段)
  // 用于搜索结果展示，例如："标题: Flutter笔记\n内容: Riverpod 是..."
  // 建议存入的内容是经过 "Context Injection" 处理过的（即包含了上下文信息）
  TextColumn get content => text()();

  // 4. 向量数据
  // BGE-Small 是 512维，MiniLM 是 384维
  TextColumn get vector => text().map(const VectorConverter())();

  // 5. 块类型 (可选)
  // e.g. "heading", "paragraph", "code_block"
  // 用于过滤：比如用户只想搜代码
  TextColumn get blockType => text().nullable()();

  // 6. 顺序索引 (可选)
  // 记录这个块在原文中的位置 (0, 1, 2...)
  // 作用：未来做 RAG 时，如果检索到了第 5 个块，可以顺便把第 4 和 第 6 个块查出来喂给 AI，增加上下文连贯性。
  IntColumn get indexInDoc => integer().nullable()();

  @override
  Set<Column> get primaryKey => {blockId};
}

@DriftDatabase(tables: [Documents, Blocks])
class NoteDatabase extends _$NoteDatabase with SyncTransactionalDbMixin {
  NoteDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      // 1. 创建表结构
      await m.createAll();

      // 2. 创建性能与同步索引
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_document_lww_dirty ON documents(is_dirty)',
      );

      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_document_lww_cursor ON documents(server_updated_at)',
      );
    },
  );
}

@riverpod
Future<NoteDatabase> noteDatabase(Ref ref) async {
  return await ref.watch(
    userDbStoreProvider(DatabaseId('note', (e) => NoteDatabase(e))).future,
  );
}
