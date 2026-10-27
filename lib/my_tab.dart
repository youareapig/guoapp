import 'package:flutter/material.dart';

import 'app_build.dart';
import 'core_bridge.dart';
import 'drama_actions.dart';
import 'local_store.dart';
import 'models.dart';
import 'saved_library.dart';
import 'widgets.dart';

/// 「我的」页:版本号 + 我的收藏 + 观看历史。
class MyTab extends StatelessWidget {
  const MyTab({
    super.key,
    required this.repository,
    required this.store,
    required this.version,
    required this.onOpenDrama,
    required this.onContinue,
    this.onSources,
    this.onSettings,
    this.onUsers,
    this.onAbout,
  });

  final AppRepository repository;
  final LocalStore store;
  final String version;
  final ValueChanged<Drama> onOpenDrama;
  final ValueChanged<Drama> onContinue;
  final VoidCallback? onSources;
  final VoidCallback? onSettings;
  final VoidCallback? onUsers;
  final VoidCallback? onAbout;

  static const _previewCount = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favorites = store.favorites;
    final history = store.history;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _header(context, theme),
        const SizedBox(height: 18),
        _section(
          context,
          title: '我的收藏',
          count: favorites.length,
          onShowAll: () => _openLibrary(context, history: false),
          empty: '还没有收藏。在剧目详情里点收藏,就会出现在这里。',
          children: [
            for (final drama in favorites.take(_previewCount))
              DramaTile(
                key: ValueKey('my-fav-${drama.id}'),
                drama: drama,
                repository: repository,
                subtitle: drama.episodes > 0 ? '共 ${drama.episodes} 集' : null,
                onTap: () => onOpenDrama(drama),
                onMore: () => _more(context, drama),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _section(
          context,
          title: '观看历史',
          count: history.length,
          onShowAll: () => _openLibrary(context, history: true),
          empty: '还没有观看记录。',
          children: [
            for (final entry in history.take(_previewCount))
              DramaTile(
                key: ValueKey('my-his-${entry.drama.id}'),
                drama: entry.drama,
                repository: repository,
                subtitle: entry.finished
                    ? '已看完'
                    : '看到第 ${entry.episode} 集',
                onTap: () => onContinue(entry.drama),
                onMore: () => _more(context, entry.drama),
              ),
          ],
        ),
      ],
    );
  }

  Widget _header(BuildContext context, ThemeData theme) {
    final profile = store.profile;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        appName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '版本 $version',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '当前用户:${profile.name}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onSources != null)
                  ActionChip(
                    avatar: const Icon(Icons.tune_rounded, size: 18),
                    label: const Text('站源管理'),
                    onPressed: onSources,
                  ),
                if (onUsers != null)
                  ActionChip(
                    avatar: const Icon(Icons.people_alt_rounded, size: 18),
                    label: const Text('用户管理'),
                    onPressed: onUsers,
                  ),
                if (onSettings != null)
                  ActionChip(
                    avatar: const Icon(Icons.settings_rounded, size: 18),
                    label: const Text('设置与备份'),
                    onPressed: onSettings,
                  ),
                if (onAbout != null)
                  ActionChip(
                    avatar: const Icon(Icons.info_outline_rounded, size: 18),
                    label: const Text('关于'),
                    onPressed: onAbout,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required int count,
    required VoidCallback onShowAll,
    required String empty,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '($count)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            if (count > 0)
              TextButton.icon(
                onPressed: onShowAll,
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                label: const Text('查看全部'),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (children.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text(
              empty,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ...children,
      ],
    );
  }

  void _openLibrary(BuildContext context, {required bool history}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SavedLibrary(
          repository: repository,
          store: store,
          history: history,
          onOpen: onOpenDrama,
          onContinue: onContinue,
        ),
      ),
    );
  }

  void _more(BuildContext context, Drama drama) {
    showDramaActions(context, drama: drama, store: store);
  }
}
