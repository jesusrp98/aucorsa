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

  factory AucorsaCardMovement.fromJson(Map<String, dynamic> json) {
    return AucorsaCardMovement(
      date: json['date'] as String,
      time: json['time'] as String,
      operation: json['operation'] as String,
      amount: json['amount'] as String,
      activationLabel: json['activationLabel'] as String?,
      activation: json['activation'] != null
          ? AucorsaRechargeActivation.values[json['activation'] as int]
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'time': time,
      'operation': operation,
      'amount': amount,
      'activationLabel': activationLabel,
      'activation': activation?.index,
    };
  }

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
