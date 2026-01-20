import 'package:ai_api/ai_api.dart';
import 'package:app_core/di.dart';

import 'service/bge_text_encoder.dart';

class AIApiOverride {
  AIApiOverride._();

  static Future<TextEncoder> textEncoder(Ref ref) async {
    return BgeTextEncoder();
  }
}
