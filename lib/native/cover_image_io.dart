import 'dart:io';

import 'package:flutter/widgets.dart';

ImageProvider coverImageProvider(String path) => FileImage(File(path));

Widget coverImage(
  String path, {
  required Widget Function(Object error, StackTrace? stack) errorBuilder,
}) => Image.file(
  File(path),
  fit: BoxFit.cover,
  cacheWidth: 440,
  excludeFromSemantics: true,
  errorBuilder: (_, error, stack) => errorBuilder(error, stack),
);
