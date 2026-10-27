import 'package:flutter/material.dart';

import '../core_bridge.dart';
import '../local_store.dart';
import '../models.dart';

/// Web 预览:不接真实播放器,弹一个假的面板展示这一集的信息。
Future<void> openPlaybackDirectly(
  BuildContext context, {
  required Drama drama,
  required AppRepository repository,
  required LocalStore store,
}) async {
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(drama.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Web 预览模式,这里不会真的播放。'),
            SizedBox(height: 12),
            Text('共 ${drama.episodes} 集', style: Theme.of(context).textTheme.bodySmall),
            if (drama.description.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(drama.description, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}
