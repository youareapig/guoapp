import 'dart:convert';

/// Web 预览用的假数据:让整个 UI 在浏览器里跑起来,不依赖 Go 核心。
///
/// 仅用于本地 UI 预览,不会打进 Android/Windows 正式包。
String nativeRequest(String body) {
  final input = jsonDecode(body) as Map<String, dynamic>;
  final action = (input['action'] ?? '').toString();
  final payload = <String, dynamic>{};
  switch (action) {
    case 'initialize':
      payload['ok'] = true;
    case 'recommendations':
    case 'catalog':
      payload['items'] = _dramas;
      payload['hasMore'] = false;
      payload['page'] = 1;
      payload['fresh'] = true;
    case 'detail':
      final drama = _dramaFor(input);
      payload['drama'] = drama;
      payload['chapters'] = _chapters(drama);
    case 'cover':
      final drama = _dramaFor(input);
      payload['path'] = _coverUrl(drama);
      payload['heic'] = false;
    case 'resolve':
    case 'preload':
      payload['url'] =
          'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';
      payload['headers'] = <String, String>{};
      payload['quality'] = 0;
      payload['qualities'] = <Map<String, dynamic>>[];
      payload['session'] = 'mock';
    case 'danmaku':
      payload['comments'] = <Map<String, dynamic>>[];
    case 'rankings':
      payload['boards'] = <Map<String, dynamic>>[];
    case 'sourceStatus':
      payload['state'] = 'ready';
    default:
      payload['ok'] = true;
  }
  // Go 核心的响应约定:{"ok":true,"data":{...}}
  return jsonEncode({'ok': true, 'data': payload});
}

Future<Map<String, dynamic>> runNativeRequest(String body) async =>
    jsonDecode(nativeRequest(body)) as Map<String, dynamic>;

Future<bool> nativeFileExists(String target) async => false;

/// 依据请求里的 drama 找到对应的假剧目。
Map<String, dynamic> _dramaFor(Map<String, dynamic> input) {
  final raw = input['drama'];
  final id = raw is Map ? (raw['id'] ?? '').toString() : '';
  for (final drama in _dramas) {
    if (drama['id'] == id) return drama;
  }
  return _dramas.first;
}

String _coverUrl(Map<String, dynamic> drama) =>
    'https://picsum.photos/seed/${drama['id']}/360/540';

List<Map<String, dynamic>> _chapters(Map<String, dynamic> drama) {
  final count = (drama['episodes'] as int?) ?? 12;
  return [
    for (var i = 1; i <= count; i++)
      {
        'id': '${drama['id']}-$i',
        'title': '第$i集',
        'currentEpisode': i,
        'vip': i > count - 2,
        'vertical': true,
      },
  ];
}

const _demo = <String, dynamic>{
  'source': 'hongguo',
  'vip': false,
  'metadataSchema': 1,
};

final List<Map<String, dynamic>> _dramas = [
  {
    ..._demo,
    'id': 'demo-1',
    'sourceId': '7588802892412406808',
    'title': '总裁的替身新娘',
    'description': '她替姐姐出嫁，却没想到嫁给了传闻中不近女色的总裁。',
    'episodes': 96,
    'category': 'short_play',
    'heat': '128.6万',
    'views': '2.4亿',
    'tags': ['甜宠', '豪门'],
    'onlineDate': '2026-10-01',
  },
  {
    ..._demo,
    'id': 'demo-2',
    'sourceId': '7588802892412406809',
    'title': '重生之我在古代当卷王',
    'description': '带着记忆回到十年前，这一次她要把错过的都拿回来。',
    'episodes': 120,
    'category': 'short_play',
    'heat': '98.2万',
    'views': '1.8亿',
    'tags': ['重生', '逆袭'],
  },
  {
    ..._demo,
    'id': 'demo-3',
    'sourceId': '7588802892412406810',
    'title': '闪婚后被大佬宠上天',
    'description': '领证当天她只想要个期限 Marriage，没想到对方直接当真。',
    'episodes': 80,
    'category': 'short_play',
    'heat': '156.3万',
    'views': '3.1亿',
    'tags': ['闪婚', '甜宠'],
    'vip': true,
  },
  {
    ..._demo,
    'id': 'demo-4',
    'sourceId': '7588802892412406811',
    'title': '穿书后我成了反派他妈',
    'description': '穿成书里最惨的女配，她决定提前带跑全家。',
    'episodes': 64,
    'category': 'short_play',
    'heat': '77.9万',
    'views': '9800万',
    'tags': ['穿书', '家庭'],
  },
  {
    ..._demo,
    'id': 'demo-5',
    'sourceId': '7588802892412406812',
    'title': '战神归来之都市传说',
    'description': '三年戎马归来的战神低调入职，第一天就被董事长闺女看上了。',
    'episodes': 150,
    'category': 'short_play',
    'heat': '201.4万',
    'views': '4.7亿',
    'tags': ['战神', '爽文'],
  },
  {
    ..._demo,
    'id': 'demo-6',
    'sourceId': '7588802892412406813',
    'title': '萌宝助攻：爹地快签字',
    'description': '五岁的小包子带着天才计划，誓要把不近女色的爹地拿下。',
    'episodes': 88,
    'category': 'short_play',
    'heat': '112.5万',
    'views': '2.2亿',
    'tags': ['萌宝', '团宠'],
  },
  {
    ..._demo,
    'id': 'demo-7',
    'sourceId': '7588802892412406814',
    'title': '深夜食堂：一碗面救一个人',
    'description': '凌晨两点的面摊，藏着城市里最动人的故事。',
    'episodes': 52,
    'category': 'short_play',
    'heat': '43.1万',
    'views': '5600万',
    'tags': ['治愈', '现实'],
  },
  {
    ..._demo,
    'id': 'demo-8',
    'sourceId': '7588802892412406815',
    'title': '国民影帝的野路子女友',
    'description': '顶流影帝翻车，评论区骂声一片，只有她递了张纸巾。',
    'episodes': 76,
    'category': 'short_play',
    'heat': '89.7万',
    'views': '1.5亿',
    'tags': ['娱乐圈', '甜宠'],
  },
];
