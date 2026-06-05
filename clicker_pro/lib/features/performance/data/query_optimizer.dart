/// Query optimization helpers for Drift tables.
///
/// Provides index suggestions and query analysis placeholders. Actual
/// migration changes are avoided here — recommendations are documented
/// for the team to apply via proper Drift migration steps.
class QueryOptimizer {
  QueryOptimizer._();

  static const Map<String, List<IndexSuggestion>> tableSuggestions = {
    'BookingsTable': [
      IndexSuggestion(
        columns: ['date', 'shift', 'studioId'],
        reason: 'Primary query pattern: date-range filtered by shift + studio',
      ),
      IndexSuggestion(
        columns: ['status'],
        reason: 'Frequent status-based list filtering',
      ),
      IndexSuggestion(
        columns: ['clientId'],
        reason: 'Client detail view joins bookings by clientId',
      ),
    ],
    'PaymentsTable': [
      IndexSuggestion(
        columns: ['eventId'],
        reason: 'Booking detail loads payments by eventId',
      ),
      IndexSuggestion(
        columns: ['date'],
        reason: 'Finance reports aggregate payments by date range',
      ),
    ],
    'ClientsTable': [
      IndexSuggestion(
        columns: ['ownerId'],
        reason: 'Role-scoped queries filter by ownerId',
      ),
      IndexSuggestion(
        columns: ['name'],
        reason: 'Client search queries on name field',
      ),
    ],
    'TasksTable': [
      IndexSuggestion(
        columns: ['bookingId'],
        reason: 'Booking detail loads associated tasks',
      ),
      IndexSuggestion(
        columns: ['status', 'assignedTo'],
        reason: 'Team task board filters by status + assignee',
      ),
    ],
  };

  /// Returns index suggestions for the given table.
  static List<IndexSuggestion> suggestIndexes(String tableName) {
    return tableSuggestions[tableName] ?? [];
  }

  /// Returns all suggestions across every tracked table.
  static Map<String, List<IndexSuggestion>> allSuggestions() {
    return Map.unmodifiable(tableSuggestions);
  }

  /// Placeholder for EXPLAIN-style query analysis.
  ///
  /// In a production setting this would run `EXPLAIN QUERY PLAN` via the
  /// Drift database connection and parse the output into a structured
  /// result. For now it returns the SQL annotated with comments about
  /// expected behavior.
  static QueryAnalysis explainQuery(String sql) {
    final trimmed = sql.trim().toUpperCase();
    final suggestions = <String>[];

    if (trimmed.startsWith('SELECT')) {
      if (!trimmed.contains('WHERE')) {
        suggestions.add('Full table scan — consider adding a WHERE clause');
      }
      if (!trimmed.contains('ORDER BY')) {
        suggestions.add(
          'Missing ORDER BY — pagination may produce inconsistent results',
        );
      }
      if (trimmed.contains('LIKE') || trimmed.contains('LIKE \'%')) {
        suggestions.add(
          'Leading-wildcard LIKE prevents index usage — consider '
          'full-text search for text-heavy filters',
        );
      }
    }

    if (trimmed.startsWith('INSERT') || trimmed.startsWith('UPDATE')) {
      if (trimmed.contains('OR REPLACE')) {
        suggestions.add(
          'OR REPLACE triggers implicit DELETE + INSERT — '
          'verify uniqueness constraints match your intent',
        );
      }
    }

    return QueryAnalysis(
      sql: sql,
      suggestions: suggestions,
      estimatedComplexity: suggestions.isEmpty ? 'simple' : 'review',
    );
  }
}

/// Describes a recommended index for a Drift table.
class IndexSuggestion {
  const IndexSuggestion({required this.columns, required this.reason});

  final List<String> columns;
  final String reason;

  String get indexName => 'idx_${columns.join("_")}';

  @override
  String toString() =>
      'IndexSuggestion(name: $indexName, columns: $columns, reason: $reason)';
}

/// Result of a query analysis pass.
class QueryAnalysis {
  const QueryAnalysis({
    required this.sql,
    required this.suggestions,
    required this.estimatedComplexity,
  });

  final String sql;
  final List<String> suggestions;
  final String estimatedComplexity;

  bool get hasIssues => suggestions.isNotEmpty;
}
