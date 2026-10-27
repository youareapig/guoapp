// ============================================================
//  Web 预览入口
//
//  用法: flutter run -d chrome --target=lib/web_main.dart
//
//  数据走 lib/native/native_bridge_web.dart 的假数据,
//  用来快速看 UI 效果,不会碰 Go 核心,也不需要 Java / Gradle。
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_build.dart';
import 'app_theme.dart';
import 'core_bridge.dart';
import 'local_store.dart';
import 'swipe_feed_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = NativeRepository();
  try {
    await repository.initialize();
  } catch (_) {
    // 预览模式:核心不可用也照常跑,数据由 mock 提供
  }
  final preferences = await SharedPreferences.getInstance();
  final store = LocalStore(preferences);
  repository.access = store;
  runApp(WebPreviewApp(repository: repository, store: store));
}

class WebPreviewApp extends StatelessWidget {
  const WebPreviewApp({
    super.key,
    required this.repository,
    required this.store,
  });

  final AppRepository repository;
  final LocalStore store;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '$appName · 预览',
    debugShowCheckedModeBanner: false,
    locale: const Locale('zh', 'CN'),
    supportedLocales: const [Locale('zh', 'CN')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ThemeMode.system,
    home: WebPreviewShell(repository: repository, store: store),
  );
}

class WebPreviewShell extends StatefulWidget {
  const WebPreviewShell({
    super.key,
    required this.repository,
    required this.store,
  });

  final AppRepository repository;
  final LocalStore store;

  @override
  State<WebPreviewShell> createState() => _WebPreviewShellState();
}

class _WebPreviewShellState extends State<WebPreviewShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _tab,
      children: [
        SwipeFeedScreen(
          repository: widget.repository,
          store: widget.store,
        ),
        const _PreviewNote(),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (index) => setState(() => _tab = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.swipe_vertical_outlined),
          selectedIcon: Icon(Icons.swipe_vertical_rounded),
          label: '刷剧',
        ),
        NavigationDestination(
          icon: Icon(Icons.info_outline_rounded),
          selectedIcon: Icon(Icons.info_rounded),
          label: '说明',
        ),
      ],
    ),
  );
}

class _PreviewNote extends StatelessWidget {
  const _PreviewNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.devices_other_rounded,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text('Web 预览模式', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(
                '当前是浏览器预览,数据来自 mock,不会真实取流。\n'
                '用来快速确认 UI 布局、配色、文案。\n\n'
                '运行中按 r 热重载、q 退出。\n'
                '改完 Dart 代码 1 秒左右生效。',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
