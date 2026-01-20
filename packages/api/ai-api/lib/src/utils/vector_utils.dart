import 'dart:math';

class VectorUtils {
  VectorUtils._();

  /// 计算余弦相似度 (Cosine Similarity)
  /// 公式: (A . B) / (||A|| * ||B||)
  /// 结果范围: [-1.0, 1.0]。1.0 表示完全相同，0 表示正交（无关），-1 表示相反。
  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      // 维度不一致无法计算，通常应报错或返回0
      return 0.0;
    }

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    // 防止除以零
    if (normA == 0 || normB == 0) return 0.0;

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}
