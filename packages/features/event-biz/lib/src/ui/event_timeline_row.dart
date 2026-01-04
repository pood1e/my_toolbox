import 'package:app_core/utils.dart';
import 'package:event_api/event_api.dart';
import 'package:flutter/material.dart';

class EventTimelineRow extends StatelessWidget {
  final Event event;

  const EventTimelineRow({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(event.timestamp);
    // 根据 source 获取 UI 配置
    final style = SourceStyleMapper.getStyle(event.source);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧：时间
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.only(top: 18.0),
              child: Text(
                DateFormat('HH:mm').format(dateTime),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          // 中间：时间轴
          Stack(
            alignment: Alignment.center,
            children: [
              Container(width: 2, color: Colors.grey.shade200),
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: style.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: style.color.withValues(alpha: .3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 右侧：内容卡片
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 16, 16),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Source 标签
                      Row(
                        children: [
                          Icon(style.icon, size: 14, color: style.color),
                          const SizedBox(width: 4),
                          Text(
                            event.source.toUpperCase(),
                            style: TextStyle(
                              color: style.color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Content: Name
                      Text(
                        event.name,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 辅助：Source 样式映射器 ---

class SourceStyle {
  final Color color;
  final IconData icon;

  const SourceStyle(this.color, this.icon);
}

class SourceStyleMapper {
  static SourceStyle getStyle(String source) {
    switch (source.toLowerCase()) {
      case 'manual':
        return const SourceStyle(Colors.blue, Icons.edit_note);
      case 'bilibili':
        return const SourceStyle(Colors.pink, Icons.tv);
      case 'github':
        return const SourceStyle(Colors.black87, Icons.code);
      case 'health':
        return const SourceStyle(Colors.green, Icons.directions_run);
      case 'transaction':
      case 'alipay':
      case 'wechat_pay':
        return const SourceStyle(Colors.orange, Icons.attach_money);
      default:
        // 根据 source 字符串生成一个确定的随机色（可选）
        return const SourceStyle(Colors.grey, Icons.circle);
    }
  }
}
