import 'package:equatable/equatable.dart';

class AucorsaCardReference extends Equatable {
  final String number;
  final String status;

  const AucorsaCardReference({required this.number, required this.status});

  @override
  List<Object> get props => [number, status];
}

class AucorsaCard extends Equatable {
  final String number;
  final String status;
  final String title;
  final String description;
  final String balance;
  final bool canRecharge;

  const AucorsaCard({
    required this.number,
    required this.status,
    required this.title,
    required this.description,
    required this.balance,
    required this.canRecharge,
  });

  factory AucorsaCard.fromJson(Map<String, dynamic> json) => AucorsaCard(
    number: json['number'] as String,
    status: json['status'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    balance: json['balance'] as String,
    canRecharge: json['canRecharge'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'number': number,
    'status': status,
    'title': title,
    'description': description,
    'balance': balance,
    'canRecharge': canRecharge,
  };

  @override
  List<Object> get props => [
    number,
    status,
    title,
    description,
    balance,
    canRecharge,
  ];
}

enum AucorsaRechargeActivation { activated, pending }

class AucorsaCardMovement extends Equatable {
  final String date;
  final String time;
  final String operation;
  final String amount;
  final String? activationLabel;
  final AucorsaRechargeActivation? activation;

  const AucorsaCardMovement({
    required this.date,
    required this.time,
    required this.operation,
    required this.amount,
    this.activationLabel,
    this.activation,
  });

  @override
  List<Object?> get props => [
    date,
    time,
    operation,
    amount,
    activationLabel,
    activation,
  ];
}

class AucorsaCardMovements extends Equatable {
  final List<AucorsaCardMovement> movements;
  final bool hasPreviousPage;
  final bool hasNextPage;

  const AucorsaCardMovements({
    required this.movements,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  @override
  List<Object> get props => [movements, hasPreviousPage, hasNextPage];
}

class AucorsaCardsSnapshot extends Equatable {
  final List<AucorsaCard> cards;
  final DateTime updatedAt;

  const AucorsaCardsSnapshot({required this.cards, required this.updatedAt});

  @override
  List<Object> get props => [cards, updatedAt];
}
