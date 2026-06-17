/// Result of pulling remote changes from the server.
class SyncPullResult<T> {
  /// Entities that were created or updated on the server.
  final List<T> upserts;

  /// Primary key values of entities deleted on the server.
  final List<Object> deletedIds;

  /// Server-authoritative timestamp (or cursor) marking the point this pull
  /// was computed. The [SyncEngine] reuses it as the `since` watermark for the
  /// next pull, avoiding client/server clock skew.
  ///
  /// If null, the engine falls back to the client time captured before the sync.
  final DateTime? serverTime;

  const SyncPullResult({
    this.upserts = const [],
    this.deletedIds = const [],
    this.serverTime,
  });
}

/// Interface for syncing a collection with a remote data source.
///
/// Implement this for each collection that needs sync.
///
/// ```dart
/// class UserSyncAdapter implements SyncAdapter<User> {
///   final ApiClient api;
///   UserSyncAdapter(this.api);
///
///   @override
///   Future<List<User>> push(List<User> entities) async {
///     return await api.post('/users/batch', entities);
///   }
///
///   @override
///   Future<void> pushDeletes(List<Object> ids) async {
///     await api.delete('/users/batch', ids);
///   }
///
///   @override
///   Future<SyncPullResult<User>> pull({DateTime? since}) async {
///     final response = await api.get('/users/changes', since: since);
///     return SyncPullResult(
///       upserts: response.upserts,
///       deletedIds: response.deletedIds,
///       // Authoritative cursor for the next pull (recommended). See below.
///       serverTime: response.serverTime,
///     );
///   }
/// }
/// ```
///
/// ### Coalescing
///
/// You don't need to deduplicate inside [push]: the [SyncEngine] already folds
/// repeated offline edits so each entity appears at most once per batch (e.g.
/// ten local updates arrive as one entity, an offline create-then-delete is
/// dropped entirely).
abstract class SyncAdapter<T> {
  /// Pushes created/updated entities to the remote server.
  ///
  /// Returns the server-confirmed versions of the entities
  /// (which may include server-assigned timestamps, ids, etc.).
  Future<List<T>> push(List<T> entities);

  /// Notifies the server about locally deleted entities.
  Future<void> pushDeletes(List<Object> ids);

  /// Pulls remote changes since [since].
  ///
  /// If [since] is null, pulls all data (initial sync).
  Future<SyncPullResult<T>> pull({DateTime? since});
}
