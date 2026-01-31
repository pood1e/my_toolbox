import 'package:app_core/di.dart';
import 'package:app_core/object.dart';
import 'package:flutter/material.dart';

import 'models.dart';

part 'interfaces.g.dart';

/// 节点渲染器接口
/// 接收一个 Node，产出一个 Widget
abstract class NodeRenderer {
  /// 唯一标识符 (存入数据库 PresentationTrait 的值)
  String get id;

  /// 核心构建方法
  Widget build(BuildContext context, WidgetRef ref, String nodeId);
}

/// 计算当前 Node 应该使用哪个渲染器 ID
@riverpod
Future<NodeRenderer> activeRenderer(Ref ref, String nodeId) async {
  throw NotOverrideError();
  // return NodeEditorRenderer();
}

// /// 基础
// abstract class TraitUiRenderer<T extends Trait> {
//   /// 这个渲染器负责哪种 TraitType
//   TraitType get type;
//
//   /// 渲染逻辑
//   Widget build(BuildContext context, WidgetRef ref, T trait);
// }
//
// /// 渲染器支持渲染哪几种Trait
// @riverpod
// Map<TraitType, TraitUiRenderer> traitUiRegistry(Ref ref, String renderId) {
//   return {TraitType.name: NameFieldRenderer()};
// }
//
// class NameFieldRenderer extends TraitUiRenderer<Trait> {
//   @override
//   TraitType get type => TraitType.name;
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref, Trait trait) {
//     return TextField(/* ... */);
//   }
// }
