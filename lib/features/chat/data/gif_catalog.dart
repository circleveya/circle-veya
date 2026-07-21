/// Kuratierte Reaktions-GIFs (CDN), durchsuchbar ohne API-Key.
class CatalogGif {
  const CatalogGif({
    required this.id,
    required this.url,
    required this.previewUrl,
    required this.tags,
  });

  final String id;
  final String url;
  final String previewUrl;
  final List<String> tags;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return tags.any((t) => t.toLowerCase().contains(q));
  }
}

CatalogGif _gif(String id, List<String> tags) => CatalogGif(
      id: id,
      url: 'https://media.giphy.com/media/$id/giphy.gif',
      previewUrl: 'https://media.giphy.com/media/$id/200w.gif',
      tags: tags,
    );

final kCatalogGifs = <CatalogGif>[
  _gif('3o7abKhOpu0NwenH3O', ['lacht', 'lol', 'funny', 'lachen', 'haha']),
  _gif('l0MYt5jPR6QX5pnqM', ['clap', 'applaus', 'bravo', 'klatschen']),
  _gif('111ebonMs90YLu', ['love', 'liebe', 'herz', 'heart']),
  _gif('3oEjI6SIIHBdRxXI40', ['loading', 'warten', 'thinking', 'nachdenken']),
  _gif('26BRv0ThheHdLhTfk', ['yes', 'ja', 'ok', 'richtig', 'correct']),
  _gif('d2lcHJCG2X8xnXzq', ['no', 'nein', 'nope', 'stop']),
  _gif('l3q2K5jinAlChoCLS', ['wow', 'omg', 'überrascht', 'shocked']),
  _gif('5GoVLqeAOo6PK', ['happy', 'glücklich', 'freu', 'yay']),
  _gif('l0MYC0LajbaPoEADe', ['cry', 'weinen', 'sad', 'traurig']),
  _gif('3o6Zt481isNVuQI1l6', ['dance', 'tanzen', 'party', 'feier']),
  _gif('26ufdipQqU2lhNA4g', ['thumbs', 'daumen', 'like', 'gut']),
  _gif('l0HlvtIPzPdt2usKs', ['high five', 'abklatschen', 'team']),
  _gif('3orieUe6ejxSFzLxu0', ['fire', 'feuer', 'hot', 'lit']),
  _gif('xT0xeJpnrWC4XWcyEk', ['cool', 'nice', 'stark']),
  _gif('IsDjNJl8oXa1y', ['facepalm', 'oh no', 'peinlich', 'ups']),
  _gif('l41lVsYFsC3k9kK3C', ['mind blown', 'krass', 'wow', 'blown']),
  _gif('13HgwGsXF0aiGY', ['excited', 'aufgeregt', 'yay', 'freu']),
  _gif('26gsjCZpWErUy6ElG', ['shrug', 'keine ahnung', 'idk', 'egal']),
  _gif('3o7TKSjRrfIPjeiVyM', ['bye', 'tschüss', 'ciao', 'wave']),
  _gif('kyLYXkvQAmrMw', ['good morning', 'guten morgen', 'morgen']),
  _gif('26u4cqiYI30juCOGY', ['good night', 'gute nacht', 'nacht', 'sleep']),
  _gif('3oEjHCWdU7F4hqVQYg', ['thanks', 'danke', 'thank you']),
  _gif('l0MYGbFj9fLTVXbR6', ['hello', 'hallo', 'hi', 'hey']),
  _gif('26tnjfgWkA0t8C0ww', ['angry', 'wütend', 'mad', 'rage']),
  _gif('12NUbkX6p4xOO4', ['confused', 'verwirrt', 'hä', 'what']),
  _gif('3o6Zt6ML6BklmajXIY', ['deal', 'handshake', 'abgemacht', 'einig']),
  _gif('l0HlPystfePnAI3Q4', [
    'celebration',
    'feier',
    'party',
    'congrats',
    'glückwunsch',
  ]),
  _gif('3orieN5lFZqj7bS4x2', ['coffee', 'kaffee', 'müde']),
  _gif('26BRBKqUiq586bRVm', ['run', 'rennen', 'eilig', 'hurry']),
  _gif('xT5LMHxhOfscxPfIfm', ['ok', 'okay', 'alles klar', 'fine']),
];
