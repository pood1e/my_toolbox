// lib/ui/page/search/search_page.dart
import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../components/search/search_app_bar.dart';
import '../components/search/search_result_list.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用 Scaffold 搭建页面骨架
    return Scaffold(
      // 获取主题背景色 (支持深色模式)
      backgroundColor: Theme.of(context).colorScheme.surface,

      // 1. 顶部搜索栏 (包含输入框、模式切换)
      appBar: const SearchAppBar(),

      // 2. 搜索结果列表 (包含 Loading、Error、Empty、List 状态)
      body: const SafeArea(child: SearchResultList()),
    );
  }
}
