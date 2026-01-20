import 'dart:async';

import 'package:app_core/di.dart';
import 'package:app_core/object.dart';

part 'text_encoder.g.dart';

/// 编码任务类型 (The Intent)
/// 用于告知编码器当前的文本是用来做什么的。
/// 这一点对于非对称模型（如 BGE, E5）至关重要，它们需要根据任务添加不同的指令前缀。
enum EncoderTask {
  /// 搜索意图 (Query)
  /// e.g. 用户输入的搜索词 "如何学习 Flutter"
  query,

  /// 索引意图 (Content/Passage)
  /// e.g. 存入数据库的笔记内容 "Flutter 是 Google 开发的 UI 框架..."
  indexing,
}

/// 文本编码器抽象 (Infrastructure Layer)
/// 职责：定义将自然语言转换为向量的契约。
/// 实现：可以是本地 ONNX 模型，也可以是云端 API (OpenAI, Ollama)。
abstract class TextEncoder {
  /// --------------------------------------------------------------------------
  /// 1. 元数据 (Metadata) - 用于系统配置
  /// --------------------------------------------------------------------------

  /// 编码器的唯一标识符
  /// 用于日志记录、版本控制或数据库中的模型标记。
  /// e.g. "local-bge-small-zh-v1.5", "openai-text-embedding-3-small"
  String get id;

  /// 向量维度
  /// 数据库建表时需要此信息 (e.g. 384, 768, 1024, 1536)。
  /// 务必确保实现类返回的值与实际模型输出一致。
  int get dimension;

  /// --------------------------------------------------------------------------
  /// 2. 生命周期 (Lifecycle)
  /// --------------------------------------------------------------------------

  /// 初始化资源
  /// - 对于本地模型：加载 .onnx 文件、加载词表、初始化推理引擎。
  /// - 对于云端 API：验证 API Key 格式、预热连接（可选）。
  /// 建议实现为懒加载模式。
  Future<void> init();

  /// 释放资源
  /// - 对于本地模型：释放 ONNX Session 内存。
  /// - 对于云端 API：关闭 HTTP Client。
  void dispose();

  /// --------------------------------------------------------------------------
  /// 3. 核心能力 (Core Capability)
  /// --------------------------------------------------------------------------

  /// 将文本列表转换为向量列表
  ///
  /// [texts]: 待编码的文本列表。设计为 List 是为了支持 Batch Processing（批处理），
  ///          这在本地推理和网络请求中都能显著提升吞吐量。
  /// [task]:  当前的任务类型。默认为 [EncoderTask.indexing]。
  ///
  /// Returns: 一个二维数组，indices 对应输入的 texts。
  /// Throws:  如果初始化失败或推理/请求失败，应抛出异常。
  Future<List<List<double>>> encode(
    List<String> texts, {
    EncoderTask task = EncoderTask.indexing,
  });
}

@riverpod
Future<TextEncoder> textEncoder(Ref ref) {
  throw NotOverrideError();
}
