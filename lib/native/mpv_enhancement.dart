// 条件导出:原生走 libmpv FFI,Web 走空实现(Web 预览不需要画质增强)。
export 'mpv_enhancement_web.dart' if (dart.library.ffi) '../video_enhancement_mpv.dart';
