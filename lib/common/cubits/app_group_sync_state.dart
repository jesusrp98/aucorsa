part of 'app_group_sync_cubit.dart';

enum AppGroupSyncStatus {
  /// Nothing has been pushed yet.
  idle,
  syncing,
  synced,

  /// Not an iOS build; there is no shared container to mirror to.
  unsupported,

  /// The App Group is not provisioned. Siri and the Shortcuts app will not see
  /// the user's favourites or custom stop names until this is resolved.
  unavailable,
  failed,
}

class AppGroupSyncState extends Equatable {
  final AppGroupSyncStatus status;

  /// When the mirror last reached the container, or null if it never has.
  final DateTime? lastSyncedAt;

  const AppGroupSyncState({
    this.status = AppGroupSyncStatus.idle,
    this.lastSyncedAt,
  });

  /// Whether the App Intents layer can be expected to see current data.
  ///
  /// True while a refresh is in flight as long as an earlier one succeeded, so
  /// the UI does not flicker between states on every favourite toggle.
  bool get isMirrorAvailable =>
      status == AppGroupSyncStatus.synced ||
      (status == AppGroupSyncStatus.syncing && lastSyncedAt != null);

  /// True when the mirror is broken in a way the user could act on, as opposed
  /// to simply not applying on this platform.
  bool get needsAttention =>
      status == AppGroupSyncStatus.unavailable ||
      status == AppGroupSyncStatus.failed;

  AppGroupSyncState copyWith({
    AppGroupSyncStatus? status,
    DateTime? lastSyncedAt,
  }) {
    return AppGroupSyncState(
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  List<Object?> get props => [status, lastSyncedAt];
}
