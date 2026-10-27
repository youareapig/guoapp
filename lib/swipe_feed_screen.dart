import 'dart:async';

import 'package:flutter/material.dart';

import 'core_bridge.dart';
import 'drama_actions.dart';
import 'local_store.dart';
import 'models.dart';
import 'playback_launch_screen.dart';
import 'widgets.dart';

/// 上下滑动刷剧:竖向全屏信息流。
///
/// 上下滑动切换剧目,点任意位置进入该剧播放器,播放器内可上下滑切集、
/// 打开选集查看全集。
class SwipeFeedScreen extends StatefulWidget {
  const SwipeFeedScreen({
    super.key,
    required this.repository,
    required this.store,
  });

  final AppRepository repository;
  final LocalStore store;

  @override
  State<SwipeFeedScreen> createState() => _SwipeFeedScreenState();
}

class _SwipeFeedScreenState extends State<SwipeFeedScreen> {
  static const _genres = <(String, String)>[
    ('short_play', '真人剧'),
    ('comic_series', '漫剧'),
    ('ai_series', 'AI剧'),
  ];

  final _pages = PageController();

  String _genre = 'short_play';
  List<Drama> _items = <Drama>[];
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _generation++;
    _pages.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (_loading) return;
    if (more && !_hasMore) return;
    final generation = ++_generation;
    setState(() {
      _loading = true;
      if (!more) {
        _error = null;
      }
    });
    try {
      final page = await widget.repository.recommendations(
        _genre,
        more: more,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        if (more) {
          final seen = _items.map((item) => item.id).toSet();
          _items = <Drama>[
            ..._items,
            ...page.items.where((item) => !seen.contains(item.id)),
          ];
        } else {
          _items = page.items;
        }
        _hasMore = page.hasMore;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = error is AppFailure ? error.message : '暂时无法加载推荐';
      });
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  void _switchGenre(String genre) {
    if (genre == _genre) return;
    setState(() {
      _genre = genre;
      _items = <Drama>[];
      _hasMore = true;
      _error = null;
    });
    if (_pages.hasClients) {
      _pages.jumpToPage(0);
    }
    unawaited(_load());
  }

  void _onPageChanged(int index) {
    if (index >= _items.length - 3 && _hasMore && !_loading) {
      unawaited(_load(more: true));
    }
  }

  Future<void> _open(Drama drama) async {
    await openPlaybackDirectly(
      context,
      drama: drama,
      repository: widget.repository,
      store: widget.store,
    );
  }

  Future<void> _toggleFavorite(Drama drama) async {
    await saveUserChange(context, () => widget.store.toggleFavorite(drama));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_items.isEmpty)
            _placeholder(context)
          else
            PageView.builder(
              key: const ValueKey('swipe-feed'),
              controller: _pages,
              scrollDirection: Axis.vertical,
              onPageChanged: _onPageChanged,
              itemCount: _items.length,
              itemBuilder: (context, index) => _page(_items[index]),
            ),
          if (_items.isNotEmpty) _topBar(context),
        ],
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载推荐', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.swipe_vertical_rounded,
              color: Colors.white54,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? '暂时没有推荐内容',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => unawaited(_load()),
              child: const Text('重新加载'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              for (final (id, label) in _genres) ...[
                _chip(context, id, label),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String id, String label) {
    final selected = id == _genre;
    return GestureDetector(
      onTap: () => _switchGenre(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: .92)
              : Colors.black.withValues(alpha: .38),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.black87 : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _page(Drama drama) {
    final theme = Theme.of(context);
    final following = widget.store.following(drama.id);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => unawaited(_open(drama)),
            child: DramaCover(
              drama: drama,
              repository: widget.repository,
              radius: 0,
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 84,
          bottom: 56,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                drama.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  shadows: [
                    Shadow(blurRadius: 8, color: Colors.black54),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _meta(drama),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  shadows: [
                    Shadow(blurRadius: 6, color: Colors.black54),
                  ],
                ),
              ),
              if (drama.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  drama.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.35,
                    shadows: [
                      Shadow(blurRadius: 6, color: Colors.black54),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              FilledButton.icon(
                key: ValueKey('swipe-play-${drama.id}'),
                onPressed: () => unawaited(_open(drama)),
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: const Text('看全集'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 13,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 12,
          bottom: 40,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _action(
                icon: following == null
                    ? Icons.bookmark_border_rounded
                    : Icons.bookmark_rounded,
                label: following == null ? '追剧' : '已追',
                onTap: () => unawaited(_toggleFavorite(drama)),
              ),
              const SizedBox(height: 18),
              _action(
                icon: Icons.list_alt_rounded,
                label: '选集',
                onTap: () => unawaited(_open(drama)),
              ),
              const SizedBox(height: 18),
              DramaActionButton(
                drama: drama,
                onPressed: () => showDramaActions(
                  context,
                  drama: drama,
                  store: widget.store,
                  onContinue: () => unawaited(_open(drama)),
                ),
              ),
            ],
          ),
        ),
        if (_loading && _items.length > 1)
          const Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }

  String _meta(Drama drama) {
    final parts = <String>[];
    if (drama.episodes > 0) parts.add('共 ${drama.episodes} 集');
    if (drama.heat.isNotEmpty) parts.add('热度 ${drama.heat}');
    if (drama.views.isNotEmpty) parts.add('播放 ${drama.views}');
    if (drama.vip == true) parts.add('VIP');
    if (parts.isEmpty) return '点击进入播放';
    return parts.join(' · ');
  }

  Widget _action({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .48),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              shadows: [Shadow(blurRadius: 5, color: Colors.black54)],
            ),
          ),
        ],
      ),
    );
  }
}
