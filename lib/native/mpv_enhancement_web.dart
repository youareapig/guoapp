import 'package:media_kit/media_kit.dart';

class VideoEnhancementFailure implements Exception {
  const VideoEnhancementFailure(this.stage, [this.code = 0]);
  final String stage;
  final int code;
  @override
  String toString() => 'VideoEnhancementFailure($stage, $code)';
}

/// Web 预览下的空实现:所有写操作直接失败,让调用方走降级分支。
class VideoEnhancementMpv {
  VideoEnhancementMpv(this.player);
  final NativePlayer player;
  bool closed = false;

  Future<void> initialize() async {}

  void set(String property, String value) {
    throw const VideoEnhancementFailure('web');
  }

  void setStrings(String property, List<String> values) {
    throw const VideoEnhancementFailure('web');
  }

  void command(List<String> values) {
    throw const VideoEnhancementFailure('web');
  }

  Object? read(String property) => null;

  String? readString(String property) => null;
}
