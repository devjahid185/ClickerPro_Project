// lib/features/search/data/search_api.dart
//
// Wire-level client for the global search endpoint
// (`GET /api/search/global?q=`). The backend searches clients, events,
// team members and packages in one call and returns them grouped under
// `results`. We flatten them into a single typed list the UI can render.

import '../../../core/network/api_client.dart';

enum SearchKind { client, booking, member, package }

class SearchHit {
  const SearchHit({
    required this.kind,
    required this.id,
    required this.title,
    this.subtitle = '',
  });

  final SearchKind kind;
  final String id;
  final String title;
  final String subtitle;
}

class SearchApi {
  SearchApi(this._client);

  final ApiClient _client;

  /// Runs a global search against `GET /api/search?q=` (Laravel returns
  /// `{data: {events, clients, payments}}`). Empty for blank queries.
  Future<List<SearchHit>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final r = await _client.get('/api/search', query: {'q': q});
    final Map<String, dynamic> results;
    if (r is Map) {
      final d = r['data'] ?? r['results'] ?? r;
      results = d is Map ? d.cast<String, dynamic>() : const {};
    } else {
      results = const {};
    }

    final hits = <SearchHit>[];

    for (final c in (results['clients'] as List? ?? const [])) {
      final m = (c as Map).cast<String, dynamic>();
      hits.add(SearchHit(
        kind: SearchKind.client,
        id: (m['id'] ?? '').toString(),
        title: (m['name'] as String?)?.trim().isNotEmpty == true
            ? m['name'] as String
            : 'Unnamed client',
        subtitle: (m['phone'] as String?) ?? '',
      ));
    }

    for (final e in (results['events'] as List? ?? const [])) {
      final m = (e as Map).cast<String, dynamic>();
      hits.add(SearchHit(
        kind: SearchKind.booking,
        id: (m['id'] ?? '').toString(),
        title: (m['title'] as String?)?.trim().isNotEmpty == true
            ? m['title'] as String
            : 'Untitled booking',
        subtitle: (m['venue'] as String?) ?? '',
      ));
    }

    return hits;
  }
}
