/// Templated stand-in for Lyria's lyrics + structure output.
library;

/// The contract §3 `prompt` block: line-oriented `key: value`.
class PromptBlock {
  const PromptBlock(this.fields);

  factory PromptBlock.parse(String prompt) {
    final fields = <String, String>{};
    for (final line in prompt.split('\n')) {
      final i = line.indexOf(':');
      if (i <= 0) continue;
      final key = line.substring(0, i).trim().toLowerCase();
      final value = line.substring(i + 1).trim();
      if (key.isNotEmpty) fields[key] = value;
    }
    return PromptBlock(fields);
  }

  final Map<String, String> fields;

  String? get recipient => _nonEmpty(fields['recipient']);

  List<String> get keywords => (fields['keywords'] ?? '')
      .split('|')
      .map((k) => k.trim())
      .where((k) => k.isNotEmpty)
      .toList();

  /// Primary language subtag (`pt-BR` → `pt`, `zh-Hant` → `zh`).
  String get lyricLanguage {
    final raw = (fields['lyric_language'] ?? 'en').trim().toLowerCase();
    return raw.split(RegExp('[-_]')).first;
  }

  static String? _nonEmpty(String? v) => v == null || v.isEmpty ? null : v;
}

class _LangPack {
  const _LangPack({
    required this.intro,
    required this.verses,
    required this.chorus,
    required this.bridge,
    required this.outro,
    required this.fallbackName,
    required this.fallbackKeywords,
  });

  final String intro;

  /// Four lines; `{k1}`..`{k3}` are keyword slots.
  final List<String> verses;

  /// Two lines; the first carries `{name}` twice.
  final List<String> chorus;
  final String bridge;

  /// Carries `{name}` once.
  final String outro;
  final String fallbackName;
  final List<String> fallbackKeywords;
}

const Map<String, _LangPack> _packs = {
  'en': _LangPack(
    intro: "Oh-oh, here's a little song for today",
    verses: [
      'I remember {k1} in the morning light',
      '{k2} and laughter, everything felt right',
      'Through every season, {k3} by our side',
      'You turned the ordinary into a ride',
    ],
    chorus: [
      '{name}, {name}, this one is for you',
      'Every little note is singing it true',
    ],
    bridge: "And if the years go fast, I'll keep this melody",
    outro: 'This song is yours, {name}, forever',
    fallbackName: 'you',
    fallbackKeywords: ['sunshine', 'laughter', 'home'],
  ),
  'ja': _LangPack(
    intro: 'ラララ、今日の歌を届けよう',
    verses: [
      '{k1}の朝を思い出す',
      '{k2}と笑い声が響いてた',
      '季節が変わっても{k3}はそばに',
      '何気ない日々が宝物になる',
    ],
    chorus: ['{name}、{name}、この歌をあなたに', 'ひとつひとつの音が想いを伝える'],
    bridge: '時が過ぎても このメロディーを抱きしめて',
    outro: 'この歌は永遠に{name}のもの',
    fallbackName: 'あなた',
    fallbackKeywords: ['ひだまり', '笑顔', 'ふるさと'],
  ),
  'pt': _LangPack(
    intro: 'Lá-lá-lá, uma canção pra hoje',
    verses: [
      'Eu lembro de {k1} na luz da manhã',
      '{k2} e risadas, tudo tão bom',
      'Em cada estação, {k3} ao nosso lado',
      'Você fez do simples algo encantado',
    ],
    chorus: [
      '{name}, {name}, essa é pra você',
      'Cada notinha canta o que eu sinto',
    ],
    bridge: 'E se os anos passarem, eu guardo essa canção',
    outro: 'Essa canção é sua, {name}, pra sempre',
    fallbackName: 'você',
    fallbackKeywords: ['sol', 'risadas', 'casa'],
  ),
  'es': _LangPack(
    intro: 'La-la-la, una canción para hoy',
    verses: [
      'Recuerdo {k1} con la luz del sol',
      '{k2} y risas, todo era mejor',
      'En cada estación, {k3} junto a los dos',
      'Hiciste mágico lo que era común',
    ],
    chorus: [
      '{name}, {name}, esta es para ti',
      'Cada nota canta lo que siento aquí',
    ],
    bridge: 'Y aunque pasen los años, guardaré esta melodía',
    outro: 'Esta canción es tuya, {name}, para siempre',
    fallbackName: 'tú',
    fallbackKeywords: ['sol', 'risas', 'hogar'],
  ),
  'de': _LangPack(
    intro: 'La-la-la, ein kleines Lied für heut',
    verses: [
      'Ich denk an {k1} im Morgenlicht',
      '{k2} und Lachen, mehr brauch ich nicht',
      'In jeder Jahreszeit ist {k3} dabei',
      'Mit dir wird jeder Alltag frei',
    ],
    chorus: [
      '{name}, {name}, dieses Lied ist für dich',
      'Jeder Ton erzählt von dir und mir',
    ],
    bridge: 'Und wenn die Jahre fliegen, halt ich diese Melodie',
    outro: 'Dieses Lied gehört dir, {name}, für immer',
    fallbackName: 'du',
    fallbackKeywords: ['Sonne', 'Lachen', 'Zuhause'],
  ),
  'fr': _LangPack(
    intro: "La-la-la, une chanson pour aujourd'hui",
    verses: [
      'Je me souviens de {k1} au petit matin',
      '{k2} et nos rires, tout allait bien',
      'À chaque saison, {k3} à nos côtés',
      'Tu rends magique chaque journée',
    ],
    chorus: [
      '{name}, {name}, celle-ci est pour toi',
      'Chaque note chante tout bas',
    ],
    bridge: 'Et si les années filent, je garde cette mélodie',
    outro: 'Cette chanson est à toi, {name}, pour toujours',
    fallbackName: 'toi',
    fallbackKeywords: ['soleil', 'rires', 'maison'],
  ),
  'ko': _LangPack(
    intro: '랄랄라, 오늘을 위한 노래',
    verses: [
      '{k1}, 아침 햇살 속에 기억해',
      '{k2} 그리고 웃음소리',
      '계절이 바뀌어도 {k3} 곁에 있어',
      '평범한 하루가 특별해졌어',
    ],
    chorus: ['{name}, {name}, 이 노래는 너를 위해', '모든 음표가 마음을 전해'],
    bridge: '시간이 흘러도 이 멜로디를 간직할게',
    outro: '이 노래는 영원히 {name}의 것',
    fallbackName: '너',
    fallbackKeywords: ['햇살', '웃음', '우리 집'],
  ),
  'hi': _LangPack(
    intro: 'ला-ला-ला, आज के लिए एक गीत',
    verses: [
      'सुबह की रोशनी में {k1} याद है',
      '{k2} और हँसी, सब कुछ खास है',
      'हर मौसम में {k3} साथ है',
      'तुमने हर दिन को जादू बना दिया',
    ],
    chorus: [
      '{name}, {name}, यह गीत तुम्हारे लिए',
      'हर सुर कहता है दिल की बात',
    ],
    bridge: 'साल बीत जाएँ, यह धुन मैं संभाल कर रखूँ',
    outro: 'यह गीत हमेशा {name} का है',
    fallbackName: 'तुम',
    fallbackKeywords: ['धूप', 'हँसी', 'घर'],
  ),
  'id': _LangPack(
    intro: 'La-la-la, sebuah lagu untuk hari ini',
    verses: [
      'Aku ingat {k1} di pagi hari',
      '{k2} dan tawa, semua terasa berarti',
      'Di setiap musim, {k3} menemani',
      'Kau buat hari biasa jadi istimewa',
    ],
    chorus: [
      '{name}, {name}, lagu ini untukmu',
      'Setiap nada menyanyikan rasaku',
    ],
    bridge: 'Walau tahun berlalu, kusimpan melodi ini',
    outro: 'Lagu ini milikmu, {name}, selamanya',
    fallbackName: 'kamu',
    fallbackKeywords: ['mentari', 'tawa', 'rumah'],
  ),
  'vi': _LangPack(
    intro: 'La-la-la, một bài hát cho hôm nay',
    verses: [
      'Mình nhớ {k1} trong nắng sớm mai',
      '{k2} và tiếng cười, chẳng thể phai',
      'Mỗi mùa trôi qua, {k3} vẫn ở đây',
      'Ngày bình thường hóa thành điều hay',
    ],
    chorus: [
      '{name}, {name}, bài hát này dành cho bạn',
      'Từng nốt nhạc nói hộ lòng mình',
    ],
    bridge: 'Dù năm tháng trôi, mình giữ mãi giai điệu này',
    outro: 'Bài hát này mãi là của {name}',
    fallbackName: 'bạn',
    fallbackKeywords: ['nắng', 'tiếng cười', 'nhà'],
  ),
  'tr': _LangPack(
    intro: 'La-la-la, bugün için bir şarkı',
    verses: [
      'Sabah ışığında {k1} aklımda',
      '{k2} ve kahkahalar, hepsi yanımda',
      'Her mevsimde {k3} hep bizimle',
      'Sıradan günler döndü bir şiire',
    ],
    chorus: [
      '{name}, {name}, bu şarkı senin için',
      'Her nota anlatıyor içimdekini',
    ],
    bridge: 'Yıllar geçse de saklarım bu melodiyi',
    outro: 'Bu şarkı sonsuza dek senin, {name}',
    fallbackName: 'sen',
    fallbackKeywords: ['güneş', 'kahkaha', 'yuva'],
  ),
  'zh': _LangPack(
    intro: '啦啦啦，今天为你唱一首歌',
    verses: ['想起清晨里的{k1}', '{k2}和笑声都在身边', '每个季节都有{k3}相伴', '平凡的日子也闪闪发光'],
    chorus: ['{name}，{name}，这首歌送给你', '每个音符都在说心里话'],
    bridge: '就算时光飞逝，我也珍藏这段旋律',
    outro: '这首歌永远属于{name}',
    fallbackName: '你',
    fallbackKeywords: ['阳光', '笑声', '家'],
  ),
};

/// Languages with a dedicated template (anything else falls back to `en`).
Set<String> get supportedLyricLanguages => _packs.keys.toSet();

/// Generates lyrics for a job. User [userLyrics] are echoed verbatim (PRD
/// §7.2 "Use exactly these lyrics"); otherwise lines are templated in the
/// block's `lyric_language`, naming the recipient ≥1× (clip) / ≥2× (song),
/// with `[Intro]`/`[Verse]`/`[Chorus]` (+ `[Verse 2]`/`[Bridge]`/`[Outro]`).
String generateLyrics({
  required PromptBlock prompt,
  required bool isSong,
  String? userLyrics,
}) {
  if (userLyrics != null && userLyrics.trim().isNotEmpty) {
    return userLyrics.trim();
  }
  final pack = _packs[prompt.lyricLanguage] ?? _packs['en']!;
  final name = prompt.recipient ?? pack.fallbackName;
  final kws = prompt.keywords;
  String k(int i) => i < kws.length ? kws[i] : pack.fallbackKeywords[i];
  String fill(String line) => line
      .replaceAll('{name}', name)
      .replaceAll('{k1}', k(0))
      .replaceAll('{k2}', k(1))
      .replaceAll('{k3}', k(2));

  final chorus = ['[Chorus]', ...pack.chorus.map(fill)];
  final lines = <String>[
    '[Intro]',
    pack.intro,
    '',
    '[Verse]',
    fill(pack.verses[0]),
    fill(pack.verses[1]),
    '',
    ...chorus,
  ];
  if (isSong) {
    lines.addAll([
      '',
      '[Verse 2]',
      fill(pack.verses[2]),
      fill(pack.verses[3]),
      '',
      ...chorus,
      '',
      '[Bridge]',
      pack.bridge,
      '',
      ...chorus,
      '',
      '[Outro]',
      fill(pack.outro),
    ]);
  }
  return lines.join('\n');
}

/// Section timeline (seconds) for the fixture audio.
List<Map<String, Object>> structureFor({required bool isSong}) {
  const clip = [('Intro', 0, 3), ('Verse', 3, 15), ('Chorus', 15, 30)];
  const song = [
    ('Intro', 0, 8),
    ('Verse 1', 8, 30),
    ('Chorus', 30, 45),
    ('Verse 2', 45, 67),
    ('Chorus', 67, 82),
    ('Bridge', 82, 97),
    ('Chorus', 97, 112),
    ('Outro', 112, 120),
  ];
  return [
    for (final (section, start, end) in isSong ? song : clip)
      {'section': section, 'start': start.toDouble(), 'end': end.toDouble()},
  ];
}
