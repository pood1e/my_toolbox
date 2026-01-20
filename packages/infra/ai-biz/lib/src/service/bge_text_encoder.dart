import 'dart:math';
import 'dart:typed_data';

import 'package:ai_api/ai_api.dart';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

import '../utils/bert_tokenizer.dart';

class BgeTextEncoder implements TextEncoder {
  OrtSession? _session;
  BertTokenizer? _tokenizer;

  // BGE-Small 的维度是 512 (Base 是 768)
  @override
  int get dimension => 512;

  // 配置最大长度
  static const int _maxLen = 512;

  @override
  String get id => 'local-bge-small-zh-v1.5';

  // 资源路径 (根据你的实际位置修改)
  static const String _modelPath =
      'packages/ai_biz/assets/models/model_quantized.onnx';
  static const String _vocabPath = 'packages/ai_biz/assets/models/vocab.txt';

  // BGE 官方推荐的中文查询前缀
  static const String _queryInstruction = '为这个句子生成表示以用于检索相关文章：';

  @override
  Future<void> init() async {
    if (_session != null) return;
    OrtEnv.instance.init();

    final rawAssetFile = await rootBundle.load(_modelPath);
    final bytes = rawAssetFile.buffer.asUint8List();
    final sessionOptions = OrtSessionOptions();
    sessionOptions.setIntraOpNumThreads(2); // 限制线程数
    _session = OrtSession.fromBuffer(bytes, sessionOptions);

    _tokenizer = await BertTokenizer.loadFromAssets(_vocabPath);
  }

  @override
  Future<List<List<double>>> encode(
    List<String> texts, {
    EncoderTask task = EncoderTask.indexing,
  }) async {
    if (_session == null || _tokenizer == null) await init();

    final List<List<double>> results = [];
    for (var text in texts) {
      String inputText = text;
      if (task == EncoderTask.query) {
        inputText = '$_queryInstruction$text';
      }
      // 打印来看看是不是前缀加对了
      // print('Encoding Input: $inputText');
      results.add(_runInference(inputText));
    }
    return results;
  }

  List<double> _runInference(String text) {
    // 1. 分词
    List<int> ids = _tokenizer!.tokenize(text);

    // 截断
    if (ids.length > _maxLen) {
      ids = ids.sublist(0, _maxLen - 1);
      ids.add(_tokenizer!.sepId);
    }

    final int actualLen = ids.length;

    // 2. Padding
    while (ids.length < _maxLen) {
      ids.add(_tokenizer!.padId);
    }

    // 3. Mask (关键：实际内容为1，Padding为0)
    final List<int> mask = List.filled(_maxLen, 0);
    for (int i = 0; i < actualLen; i++) {
      mask[i] = 1;
    }

    // Token Types
    final List<int> tokenTypes = List.filled(_maxLen, 0);

    // 4. 创建 Tensor
    final shape = [1, _maxLen];
    final inputIdTensor = OrtValueTensor.createTensorWithDataList(
      Int64List.fromList(ids),
      shape,
    );
    final attentionMaskTensor = OrtValueTensor.createTensorWithDataList(
      Int64List.fromList(mask),
      shape,
    );
    final tokenTypeTensor = OrtValueTensor.createTensorWithDataList(
      Int64List.fromList(tokenTypes),
      shape,
    );

    final inputs = {
      'input_ids': inputIdTensor,
      'attention_mask': attentionMaskTensor,
      'token_type_ids': tokenTypeTensor,
    };

    // 5. 运行推理
    final runOptions = OrtRunOptions();
    final outputs = _session!.run(runOptions, inputs);

    // 释放输入
    runOptions.release();
    inputIdTensor.release();
    attentionMaskTensor.release();
    tokenTypeTensor.release();

    // 6. 获取输出 (关键修复!!!)
    final outputValue = outputs[0];
    if (outputValue == null) throw Exception('Inference failed');

    // 解析嵌套结构: [Batch, Seq, Hidden]
    // 报错提示 outputValue.value 是一个包含 List<List<double>> 的 List
    final rawBatch = outputValue.value as List;

    // 取 Batch 0
    final List<dynamic> batchSequence = rawBatch[0] as List;

    // 取 Sequence 0 ([CLS] Token)
    // 这是 BGE 的语义向量所在位置
    final List<dynamic> clsRawVector = batchSequence[0] as List;

    // 转换为 List<double>
    final List<double> vector = clsRawVector
        .map((e) => (e as num).toDouble())
        .toList();

    // 释放输出
    for (var o in outputs) {
      o?.release();
    }

    // 7. L2 归一化
    return _l2Normalize(vector);
  }

  List<double> _l2Normalize(List<double> vector) {
    double sum = 0.0;
    for (var v in vector) {
      sum += v * v;
    }
    final norm = sqrt(sum);
    if (norm == 0) return vector;
    return vector.map((e) => e / norm).toList();
  }

  @override
  void dispose() {
    _session?.release();
  }
}
