import 'package:flutter/widgets.dart';

ImageProvider coverImageProvider(String path) => NetworkImage(path);

Widget coverImage(
  String path, {
  required Widget Function(Object error, StackTrace? stack) errorBuilder,
}) => Image.network(
  path,
  fit: BoxFit.cover,
  cacheWidth: 440,
  excludeFromSemantics: true,
  errorBuilder: (_, error, stack) => errorBuilder(error, stack),
);
