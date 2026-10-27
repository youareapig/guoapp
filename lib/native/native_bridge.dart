// 条件导出:原生平台走 FFI 调 Go 核心,Web 走 mock 数据。
export 'native_bridge_web.dart' if (dart.library.ffi) 'native_bridge_io.dart';
