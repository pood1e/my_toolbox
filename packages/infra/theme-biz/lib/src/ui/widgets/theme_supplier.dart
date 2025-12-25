import 'package:app_core/di.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../../domain/app_theme.dart';
import '../../state/theme_settings_notifier.dart';

void holdSplashScreen(WidgetsBinding widgetsBinding) {
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
}

class ThemeSupplier extends ConsumerWidget {
  final Widget Function(
    ThemeData lightTheme,
    ThemeData darkTheme,
    ThemeMode themeMode,
  )
  _builder;

  const ThemeSupplier({
    super.key,
    required Widget Function(
      ThemeData lightTheme,
      ThemeData darkTheme,
      ThemeMode themeMode,
    )
    builder,
  }) : _builder = builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(themeSettingsProvider);

    return settingsAsync.when(
      // A. 加载中
      // 此时原生启动屏还盖在上面，用户实际上看不到这里返回的 Widget。
      // 但为了代码健壮性，我们可以返回一个空白容器或者简单的 Loading。
      loading: () => const MaterialApp(
        home: Scaffold(body: SizedBox.shrink()),
        debugShowCheckedModeBanner: false,
      ),

      // B. 出错
      // 如果加载配置失败，必须移除启动屏，否则用户会永远卡在 Logo 界面
      error: (err, stack) {
        FlutterNativeSplash.remove(); // 【关键】出错也要移除
        return MaterialApp(
          home: Scaffold(body: Center(child: Text('启动错误: $err'))),
        );
      },
      data: (settings) {
        FlutterNativeSplash.remove();
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            ColorScheme? lightSchema;
            ColorScheme? darkSchema;
            if (settings.followSystemColor &&
                lightDynamic != null &&
                darkDynamic != null) {
              lightSchema = lightDynamic;
              darkSchema = darkDynamic;
            }
            return _builder(
              AppTheme.create(
                settings: settings,
                isDark: false,
                systemScheme: lightSchema,
              ),
              AppTheme.create(
                settings: settings,
                isDark: true,
                systemScheme: darkSchema,
              ),
              settings.themeMode,
            );
          },
        );
      },
    );
  }
}
