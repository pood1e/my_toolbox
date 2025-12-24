import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

class SpringBootPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final String color = _getLevelColor(event.level);
    final String resetColor = '\x1b[0m';

    final String timeStr = DateFormat(
      'yyyy-MM-dd HH:mm:ss.SSS',
    ).format(event.time);
    final String levelStr = event.level.name.toUpperCase().padRight(5);

    // 优先使用 event 携带的堆栈，如果没有则抓取当前堆栈
    final StackTrace stackTrace = event.stackTrace ?? StackTrace.current;
    final String? location = _extractLocation(stackTrace);

    // 关键：为了保证 IDE 100% 识别，建议将可点击路径放在括号内，并与前后内容用空格分开
    final String logLine = '$timeStr $levelStr $location: ${event.message}';

    return ['$color$logLine$resetColor'];
  }

  String? _extractLocation(StackTrace stackTrace) {
    List<String> lines = stackTrace.toString().split('\n');
    String? targetLine;

    for (var line in lines) {
      // 排除掉当前这个打印器文件和 logger 库文件
      if (!line.contains('SpringBootPrinter') &&
          !line.contains('package:logger')) {
        targetLine = line;
        break;
      }
    }

    if (targetLine == null) return null;

    // 正则提取 package:xxx/xxx.dart:line:column
    final match = RegExp(
      r'(package:[\w\.\/]+\.dart:\d+:\d+)',
    ).firstMatch(targetLine);
    if (match != null) {
      return '[${match.group(1)}]'; // 加上括号，IDE 识别率最高
    }

    return null;
  }

  String _getLevelColor(Level level) {
    switch (level) {
      case Level.debug:
        return '\x1b[34m';
      case Level.info:
        return '\x1b[32m';
      case Level.warning:
        return '\x1b[33m';
      case Level.error:
        return '\x1b[31m';
      default:
        return '';
    }
  }
}

final logger = Logger(printer: SpringBootPrinter());
