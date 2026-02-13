import 'package:flutter/material.dart';

import '../../../ui/page_renderer.dart';
import 'node_list_page.dart';

class NodeListRenderer implements PageRenderer {
  @override
  String get id => 'node_list';

  @override
  Widget render() => const NodeListPage();
}
