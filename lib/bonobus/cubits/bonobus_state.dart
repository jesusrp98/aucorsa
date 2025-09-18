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

  const BonobusState({
    this.status = BonobusStatus.initial,
    this.provider,
    this.id,
    this.balance,
    this.name,
    this.lastUpdated,
  });

  factory BonobusState.fromJson(Map<String, dynamic> json) {
    return BonobusState(
      status: BonobusStatus.values[json['status'] as int],
      provider: json['provider'] != null
          ? BonobusProvider.values[json['provider'] as int]
          : null,
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
  }) => BonobusState(
    status: status ?? this.status,
    provider: provider ?? this.provider,
    id: id ?? this.id,
    balance: balance ?? this.balance,
    name: name ?? this.name,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );

  @override
  List<Object?> get props => [status, provider, id, balance, name, lastUpdated];
}
