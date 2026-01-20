import 'package:flutter/services.dart';

class BertTokenizer {
  final Map<String, int> vocab;
  final int unkId;
  final int clsId;
  final int sepId;
  final int padId;

  final Map<String, List<int>> _cache = {};

  BertTokenizer(this.vocab)
      : unkId = vocab['[UNK]'] ?? 100,
        clsId = vocab['[CLS]'] ?? 101,
        sepId = vocab['[SEP]'] ?? 102,
        padId = vocab['[PAD]'] ?? 0;

  static Future<BertTokenizer> loadFromAssets(String path) async {
    final vocabStr = await rootBundle.loadString(path);
    final lines = vocabStr.split('\n');
    final Map<String, int> vocab = {};

    for (var i = 0; i < lines.length; i++) {
      // trim() 非常重要，处理 Windows 的 \r\n
      final token = lines[i].trim();
      if (token.isNotEmpty) {
        vocab[token] = i;
      }
    }
    return BertTokenizer(vocab);
  }

  /// 修复：只返回实际 ID，不进行 Padding，由调用方处理
  List<int> tokenize(String text) {
    if (_cache.containsKey(text)) {
      return _cache[text]!;
    }

    final List<String> tokens = [];
    final cleanText = text.toLowerCase();

    // 正则保持不变
    final RegExp pattern = RegExp(
      r'[\u4e00-\u9fa5]|'
      r'[a-zA-Z0-9]+|'
      r'[^\s\w]',
      unicode: true,
    );

    final matches = pattern.allMatches(cleanText);

    for (final match in matches) {
      final word = match.group(0)!;
      _wordPieceTokenize(word, tokens);
    }

    // 组装 ID
    final List<int> ids = [clsId];
    for (var token in tokens) {
      // 这里的截断逻辑移到外部，或者保留在这里作为硬限制
      ids.add(vocab[token] ?? unkId);
    }
    ids.add(sepId);

    // Debug 打印：看看分词结果是否全是 UNK
    // print('Tokenizer Debug: "$text" -> $tokens -> $ids');

    _cache[text] = ids;
    return ids;
  }

  void _wordPieceTokenize(String word, List<String> tokens) {
    // 逻辑保持不变...
    if (word.length > 100) {
      tokens.add('[UNK]');
      return;
    }
    if (vocab.containsKey(word)) {
      tokens.add(word);
      return;
    }
    int start = 0;
    while (start < word.length) {
      int end = word.length;
      String? curSubStr;
      while (start < end) {
        String subStr = word.substring(start, end);
        if (start > 0) subStr = '##$subStr';
        if (vocab.containsKey(subStr)) {
          curSubStr = subStr;
          break;
        }
        end--;
      }
      if (curSubStr == null) {
        tokens.add('[UNK]');
        return;
      } else {
        tokens.add(curSubStr);
        start = end;
      }
    }
  }
}