import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

typedef _NativeRequest = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _DartRequest = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _NativeFree = Void Function(Pointer<Utf8>);
typedef _DartFree = void Function(Pointer<Utf8>);

/// 调用 Go 核心(libduanju_core.so / duanju_core.dll)。
String nativeRequest(String body) {
  final DynamicLibrary library;
  if (Platform.isAndroid) {
    library = DynamicLibrary.open('libduanju_core.so');
  } else if (Platform.isWindows) {
    library = DynamicLibrary.open(
      path.join(path.dirname(Platform.resolvedExecutable), 'duanju_core.dll'),
    );
  } else if (Platform.isIOS) {
    library = DynamicLibrary.process();
  } else {
    throw UnsupportedError('当前首版支持 Android 手机和 Windows 电脑');
  }
  final request = library.lookupFunction<_NativeRequest, _DartRequest>(
    'DuanjuRequest',
  );
  final free = library.lookupFunction<_NativeFree, _DartFree>('DuanjuFree');
  final input = body.toNativeUtf8();
  Pointer<Utf8> output = nullptr;
  try {
    output = request(input);
    if (output == nullptr) {
      throw StateError('本地核心没有返回结果');
    }
    return output.toDartString();
  } finally {
    malloc.free(input);
    if (output != nullptr) {
      free(output);
    }
  }
}

/// 在独立 isolate 里执行,避免阻塞 UI。
Future<Map<String, dynamic>> runNativeRequest(String body) async {
  final raw = await Isolate.run(() => nativeRequest(body));
  return jsonDecode(raw) as Map<String, dynamic>;
}

/// 本地文件是否存在(封面缓存)。
Future<bool> nativeFileExists(String target) => File(target).exists();
