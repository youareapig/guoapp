// 条件导出:原生用 FileImage 读本地封面缓存,Web 用 NetworkImage 读网络图。
export 'cover_image_web.dart' if (dart.library.io) 'cover_image_io.dart';
