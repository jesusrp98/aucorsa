part of 'bonobus_cubit.dart';

enum BonobusStatus { initial, loading, loaded }

enum BonobusProvider { aucorsa, consorcio }

class BonobusState extends Equatable {
  final BonobusStatus status;
  final BonobusProvider? provider;
  final String? id;
  final String? balance;
  final String? name;
  final DateTime? lastUpdated;

  /// Message of the last failed load, or `null` when nothing failed.
  ///
  /// It is empty when the provider gave no message worth showing, so the UI
  /// falls back to its own generic text. Never persisted: an error belongs to
  /// the session that produced it.
  final String? error;

  const BonobusState({
    this.status = BonobusStatus.initial,
    this.provider,
    this.id,
    this.balance,
    this.name,
    this.lastUpdated,
    this.error,
  });

  factory BonobusState.fromJson(Map<String, dynamic> json) {
    final provider = json['provider'] != null
        ? BonobusProvider.values[json['provider'] as int]
        : null;

    return BonobusState(
      status: BonobusStatus.values[json['status'] as int],
      provider: provider,
      id: json['id'] as String?,
      balance: json['balance'] as String?,
      name: json['name'] as String?,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.index,
      'provider': provider?.index,
      'id': id,
      'balance': balance,
      'name': name,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  BonobusState copyWith({
    BonobusStatus? status,
    BonobusProvider? provider,
    String? id,
    String? balance,
    String? name,
    DateTime? lastUpdated,
    String? error,
    bool clearError = false,
  }) => BonobusState(
    status: status ?? this.status,
    provider: provider ?? this.provider,
    id: id ?? this.id,
    balance: balance ?? this.balance,
    name: name ?? this.name,
    lastUpdated: lastUpdated ?? this.lastUpdated,
    error: clearError ? null : error ?? this.error,
  );

  @override
  List<Object?> get props => [
    status,
    provider,
    id,
    balance,
    name,
    lastUpdated,
    error,
  ];
}
