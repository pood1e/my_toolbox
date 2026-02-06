import 'package:app_core/object.dart';

part 'node.freezed.dart';

@freezed
abstract class Node with _$Node {
  const factory Node({required String id}) = _Node;
}

abstract class NodeContext {
  String get nodeId;
}
