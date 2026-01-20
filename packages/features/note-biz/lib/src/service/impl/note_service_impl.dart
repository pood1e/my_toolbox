import 'package:app_core/logger.dart';
import 'package:app_core/uuid.dart';
import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import '../../data/note_database.dart';
import '../../data/note_repositories.dart';
import '../note_service.dart';

class NoteServiceImpl implements NoteService {
  final DocumentRepository _docRepository;
  final ServerTimeService _timeService;
  final TextEncoder _textEncoder;
  final Uuid _uuid = Uuid();

  NoteServiceImpl({
    required DocumentRepository docRepository,
    required ServerTimeService timeService,
    required TextEncoder textEncoder,
  }) : _docRepository = docRepository,
       _timeService = timeService,
       _textEncoder = textEncoder;

  @override
  Future<String> createDocument({
    required String title,
    required Map<String, dynamic> content,
  }) async {
    final id = _uuid.v4();
    final time = _timeService.nowMs;
    await _docRepository.createDocument(
      id: id,
      title: title,
      content: content,
      nowMs: time,
    );

    _processBlocksBackground(id, title, content, time);
    return id;
  }

  @override
  Future<void> updateDocument({
    required String id,
    required String title,
    required Map<String, dynamic> content,
  }) async {
    final time = _timeService.nowMs;

    await _docRepository.updateDocument(
      id: id,
      title: title,
      content: content,
      nowMs: time,
    );
    _processBlocksBackground(id, title, content, time);
    return;
  }

  /// --------------------------------------------------------------------------
  /// 核心私有逻辑：解析 -> 计算 -> 存储
  /// --------------------------------------------------------------------------
  Future<void> _processBlocksBackground(
    String docId,
    String docTitle,
    Map<String, dynamic> contentJson,
    int versionTimestamp, // 用于乐观锁校验
  ) async {
    try {
      // 1. 初始化 AI (懒加载)
      await _textEncoder.init();

      // 2. 解析 AppFlowy JSON 为扁平节点列表
      // 而是直接解析 Map。这样能保证 JSON 里的 ID 原封不动地被读取。
      final List<_RawBlockData> rawBlocks = [];

      // contentJson 的结构通常是 { "document": { "children": [...] } }
      final documentMap = contentJson['document'] as Map<String, dynamic>?;
      if (documentMap != null && documentMap['children'] is List) {
        final children = documentMap['children'] as List;
        _parseMapRecursively(children, docTitle, rawBlocks);
      }

      // 如果文档被清空了，构造一个空的更新参数，目的是清空 DB 里的 Block
      if (rawBlocks.isEmpty) {
        final param = UpdateBlockParam(
          docId: docId,
          updatedAt: versionTimestamp,
          companions: [],
        );
        await _docRepository.updateBlocks([param]);
        return;
      }

      // 3. 批量计算向量 (Batch Embedding)
      final List<String> textsToEmbed = rawBlocks
          .map((e) => e.textForEmbedding)
          .toList();

      // 调用 Encoder 接口
      final vectors = await _textEncoder.encode(
        textsToEmbed,
        task: EncoderTask.indexing, // 标记任务类型：建立索引
      );

      // 4. 组装数据库对象
      final List<BlocksCompanion> companions = [];

      for (int i = 0; i < rawBlocks.length; i++) {
        final raw = rawBlocks[i];

        // 校验向量维度 (可选，防止模型出错)
        if (vectors[i].length != _textEncoder.dimension) {
          logger.d(
            '⚠️ Vector dim mismatch: ${vectors[i].length} vs ${_textEncoder.dimension}',
          );
          continue;
        }

        companions.add(
          BlocksCompanion.insert(
            blockId: raw.id,
            docId: docId,
            content: raw.originalContent,
            // 存原始纯文本，用于搜索展示
            vector: vectors[i],
            // 存向量
            blockType: Value(raw.type),
            // e.g. "paragraph"
            indexInDoc: Value(i), // 顺序
          ),
        );
      }

      // 5. 提交更新 (包含乐观锁校验)
      final param = UpdateBlockParam(
        docId: docId,
        updatedAt: versionTimestamp, // 关键：带着时间戳去更新
        companions: companions,
      );

      await _docRepository.updateBlocks([param]);

      // debugPrint("✅ Indexed ${companions.length} blocks for $docId");
    } catch (e, stack) {
      // 这里的错误不能抛出给 UI，只能记录日志
      logger.d('⚠️ Vector processing failed for $docId: $e\n$stack');
    }
  }

  /// [修改点 2] 手动递归解析 Map
  /// 目的：100% 忠实还原 JSON 中的 ID 和 Text，不经过任何第三方库的处理
  void _parseMapRecursively(
    List<dynamic> nodes, // children list
    String docTitle,
    List<_RawBlockData> result,
  ) {
    for (final node in nodes) {
      if (node is! Map<String, dynamic>) continue;

      // 1. 提取 ID (如果没有 ID，说明数据源有问题，跳过或生成临时ID)
      // 注意：我们在 UI 层用了 toJsonWithId，所以这里一定有 ID
      final String? id = node['id'] as String?;
      final String type = node['type'] as String? ?? 'unknown';
      final Map<String, dynamic>? data = node['data'] as Map<String, dynamic>?;

      if (id != null && data != null) {
        // 2. 提取文本
        // AppFlowy 的文本通常在 data['delta'] 里的 insert 字段
        // data 结构: { "delta": [ { "insert": "Hello" }, { "insert": "World", "attributes": {...} } ] }
        final String text = _extractTextFromDelta(data['delta']);

        // 3. 过滤有效内容
        if (text.trim().length >= 2) {
          result.add(
            _RawBlockData(
              id: id,
              type: type,
              originalContent: text,
              textForEmbedding: '$docTitle\n$text',
            ),
          );
        }
      }

      // 4. 递归处理子节点
      if (node['children'] is List) {
        _parseMapRecursively(node['children'] as List, docTitle, result);
      }
    }
  }

  /// 辅助：从 Delta 数组拼接纯文本
  String _extractTextFromDelta(dynamic delta) {
    if (delta is! List) return '';
    final buffer = StringBuffer();
    for (final op in delta) {
      if (op is Map && op['insert'] is String) {
        buffer.write(op['insert']);
      }
    }
    return buffer.toString();
  }

  @override
  Future<List<DocSearchResult>> searchByKeyword(String keyword) async {
    if (keyword.trim().isEmpty) return [];

    // 1. 搜索内容匹配的 Blocks
    // 返回: List<BlockContent> (id, docId, content)
    final matchedBlocks = await _docRepository.queryBlocksByKeyword(keyword);

    // 2. 提取所有命中内容文档的 ID 集合
    final relatedDocIds = matchedBlocks.map((b) => b.docId).toSet().toList();

    // 3. 搜索文档标题信息
    // 逻辑: (ID 在 relatedDocIds 中) OR (标题 包含 keyword)
    // 返回: List<DocTitle> (id, title)
    // 这步操作既拿到了命中内容的文档标题，也拿到了纯粹命中标题的文档
    final matchedDocs = await _docRepository.queryDocumentTitleOrIds(
      keyword,
      relatedDocIds,
    );

    // 4. 内存聚合：将 Blocks 按 DocId 分组
    final blockMap = <String, List<BlockSearchResult>>{};

    for (final block in matchedBlocks) {
      if (!blockMap.containsKey(block.docId)) {
        blockMap[block.docId] = [];
      }
      blockMap[block.docId]!.add(
        BlockSearchResult(id: block.id, content: block.content),
      );
    }

    // 5. 组装最终结果
    // 遍历 matchedDocs，填入对应的 blocks (如果没有 blocks 说明是纯标题匹配，给空列表)
    final results = matchedDocs.map((doc) {
      return DocSearchResult(
        id: doc.id,
        title: doc.title,
        blocks: blockMap[doc.id] ?? const [],
      );
    }).toList();

    return results;
  }

  // 相似度阈值
  // 低于此值的通常是不相关的噪音
  static const double _similarityThreshold = 0.45;

  @override
  Future<List<DocSearchResult>> searchBySemantic(String keyword) async {
    if (keyword.trim().isEmpty) return [];

    try {
      // 1. 初始化 & 编码 (Query Embedding)
      await _textEncoder.init();
      final queryVectors = await _textEncoder.encode([
        keyword,
      ], task: EncoderTask.query);
      final targetVector = queryVectors.first;

      // 2. 获取所有向量并计算相似度
      // 生产环境建议：这里可以使用 LRU Cache 缓存 getAllBlockVectors 的结果
      final allCandidates = await _docRepository.getAllBlockVectors();

      final List<_ScoredBlock> scoredBlocks = [];
      for (final candidate in allCandidates) {
        final score = VectorUtils.cosineSimilarity(
          targetVector,
          candidate.vector,
        );
        if (score >= _similarityThreshold) {
          scoredBlocks.add(_ScoredBlock(candidate.blockId, score));
        }
      }

      // 3. 排序并截取 Top N
      scoredBlocks.sort((a, b) => b.score.compareTo(a.score));
      final topScored = scoredBlocks.take(30).toList();

      if (topScored.isEmpty) return [];

      // =======================================================================
      // 4. 数据补全 (核心修改：分离 Block 和 Title 的查询)
      // =======================================================================

      final blockIds = topScored.map((e) => e.blockId).toList();

      // 4.1 获取 Block 纯内容 (Block 只有 id, docId, content)
      final blocks = await _docRepository.getByIds(blockIds);

      // 4.2 提取涉及到的 DocId 集合
      final docIds = blocks.map((b) => b.docId).toSet().toList();

      // 4.3 批量获取文档标题 (使用之前定义的接口)
      // queryDocumentTitleOrIds 支持传入 ids 列表来精确查找
      final docTitles = await _docRepository.queryDocumentTitleOrIds(
        '',
        docIds,
      );

      // 5. 聚合结果
      return _aggregateAndSortResults(topScored, blocks, docTitles);
    } catch (e) {
      logger.e('Semantic search error: $e');
      return [];
    }
  }

  /// 聚合逻辑：将 分数(ScoredBlock) + 内容(Block) + 标题(DocTitle) 组装在一起
  List<DocSearchResult> _aggregateAndSortResults(
    List<_ScoredBlock> scores,
    List<BlockContent> blocks,
    List<DocTitle> titles,
  ) {
    // 1. 构建快速查找表 (Lookup Tables)
    final blockMap = {for (var b in blocks) b.id: b};
    final titleMap = {for (var t in titles) t.id: t.title};

    // 2. 临时容器
    final Map<String, List<BlockSearchResult>> docBlockMap =
        {}; // docId -> Result Blocks
    final Map<String, double> docMaxScore = {}; // docId -> Max Score

    // 3. 遍历分数列表 (保持顺序)
    for (final scoreItem in scores) {
      final block = blockMap[scoreItem.blockId];
      if (block == null) continue; // 对应的 Block 可能已被物理删除

      final docId = block.docId;

      // 如果找不到标题，说明文档可能已被放入回收站或物理删除，跳过
      if (!titleMap.containsKey(docId)) continue;

      // 初始化 Map
      if (!docBlockMap.containsKey(docId)) {
        docBlockMap[docId] = [];
        // 因为 scores 是有序的，第一次遇到该 docId 的分一定是最高的
        docMaxScore[docId] = scoreItem.score;
      }

      // 添加 Block 结果
      docBlockMap[docId]!.add(
        BlockSearchResult(id: block.id, content: block.content),
      );
    }

    // 4. 组装最终结果
    final List<DocSearchResult> results = docBlockMap.entries.map((entry) {
      final docId = entry.key;
      final blockList = entry.value;

      return DocSearchResult(
        id: docId,
        title: titleMap[docId] ?? '无标题', // 从 titleMap 获取标题
        blocks: blockList,
      );
    }).toList();

    // 5. 最终排序：按文档的最高相关度排序
    results.sort((a, b) {
      final scoreA = docMaxScore[a.id] ?? 0;
      final scoreB = docMaxScore[b.id] ?? 0;
      return scoreB.compareTo(scoreA);
    });

    return results;
  }

  @override
  Future<List<DocSearchResult>> searchHybrid(String keyword) async {
    if (keyword.trim().isEmpty) return [];

    // 1. 并发执行两种搜索
    // 使用 Future.wait 同时发起 SQL 查询和 向量推理+计算
    final results = await Future.wait([
      searchByKeyword(keyword),
      searchBySemantic(keyword),
    ]);

    final keywordResults = results[0];
    final semanticResults = results[1];

    // 2. 结果合并 (Merge)
    // Map<DocId, _MergedDoc>
    final Map<String, _MergedDoc> mergedDocs = {};

    // 2.1 处理关键词结果 (优先级高，先放入)
    for (final doc in keywordResults) {
      if (!mergedDocs.containsKey(doc.id)) {
        mergedDocs[doc.id] = _MergedDoc(id: doc.id, title: doc.title);
      }

      for (final block in doc.blocks) {
        // 关键词搜出来的，isSemanticOnly = false
        mergedDocs[doc.id]!.addBlock(block.copyWith(isSemanticOnly: false));
      }
    }

    // 2.2 处理语义结果 (后放入，做去重)
    for (final doc in semanticResults) {
      if (!mergedDocs.containsKey(doc.id)) {
        mergedDocs[doc.id] = _MergedDoc(id: doc.id, title: doc.title);
      }

      for (final block in doc.blocks) {
        // 尝试添加。如果该 blockId 已经存在（说明被关键词搜到了），
        // _MergedDoc 内部逻辑应该忽略这次添加，保留关键词那个版本
        mergedDocs[doc.id]!.addBlock(
          block.copyWith(isSemanticOnly: true), // 标记为语义
          checkExist: true,
        );
      }
    }

    // 3. 转换为最终列表并排序
    final finalResults = mergedDocs.values.map((d) => d.toDto()).toList();

    // 4. 混合排序策略
    // 规则：
    // - 包含关键词匹配的文档排前面
    // - 都是关键词匹配，或者都是语义匹配，保持原有相对顺序（这里简单处理）
    // - 也可以根据命中块的数量排序
    finalResults.sort((a, b) {
      // 检查是否包含精确匹配
      final aHasExact = a.blocks.any((b) => !b.isSemanticOnly);
      final bHasExact = b.blocks.any((b) => !b.isSemanticOnly);

      if (aHasExact && !bHasExact) return -1; // a 排前
      if (!aHasExact && bHasExact) return 1;  // b 排前

      // 如果同级，按命中块数量降序
      return b.blocks.length.compareTo(a.blocks.length);
    });

    return finalResults;
  }
}

/// 内部辅助类：用于去重合并
class _MergedDoc {
  final String id;
  final String title;
  final Map<String, BlockSearchResult> blocksMap = {};

  _MergedDoc({required this.id, required this.title});

  void addBlock(BlockSearchResult block, {bool checkExist = false}) {
    // 如果 checkExist 为 true，且已经存在，则不覆盖
    // (因为存在的那个肯定是关键词匹配的，优先级更高)
    if (checkExist && blocksMap.containsKey(block.id)) {
      return;
    }
    blocksMap[block.id] = block;
  }

  DocSearchResult toDto() {
    return DocSearchResult(
      id: id,
      title: title,
      blocks: blocksMap.values.toList(),
    );
  }
}

/// 内部辅助类
class _RawBlockData {
  final String id;
  final String type;
  final String originalContent;
  final String textForEmbedding;

  _RawBlockData({
    required this.id,
    required this.type,
    required this.originalContent,
    required this.textForEmbedding,
  });
}

/// 内部私有类：用于携带分数
class _ScoredBlock {
  final String blockId;
  final double score;

  _ScoredBlock(this.blockId, this.score);
}
