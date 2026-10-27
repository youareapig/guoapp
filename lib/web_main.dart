// ============================================================
//  Web 预览入口
//
//  用法: flutter run -d chrome --target=lib/web_main.dart
//        或 .\开发.ps1  → http://127.0.0.1:8080
//
//  跑的是**真实的主界面**(HomeScreen:推荐 / 剧场 / 我的),
//  数据来自 lib/native/native_bridge_web.dart 的 mock,
//  不碰 Go 核心,也不需要 Java / Gradle。
// ============================================================
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_layout.dart';
import 'core_bridge.dart';
import 'local_store.dart';
import 'main.dart';

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
  final device = await AppDevice.detect();
  runApp(
    DuanjuApp(
      repository: repository,
      store: store,
      version: device.version,
      television: device.television,
    ),
  );
}
