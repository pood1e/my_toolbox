import '../evalutor.dart';

class DirectEvalutor implements Evalutor<String, String> {
  @override
  Future<String> eval(EvalutorContext ctx, String config) async {
    return config;
  }
}
