import 'package:equatable/equatable.dart';

class AucorsaCard extends Equatable {
  final String title;
  final String balance;

  const AucorsaCard({required this.title, required this.balance});

  @override
  List<Object> get props => [title, balance];
}

enum AucorsaRechargeActivation { activated, pending }

class AucorsaCardMovement extends Equatable {
  final String date;
  final String time;
  final String operation;
  final String amount;
  final AucorsaRechargeActivation? activation;

  const AucorsaCardMovement({
    required this.date,
    required this.time,
    required this.operation,
    required this.amount,
    this.activation,
  });

  factory AucorsaCardMovement.fromJson(Map<String, dynamic> json) {
    return AucorsaCardMovement(
      date: json['date'] as String,
      time: json['time'] as String,
      operation: json['operation'] as String,
      amount: json['amount'] as String,
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
      'activation': activation?.index,
    };
  }

  @override
  List<Object?> get props => [date, time, operation, amount, activation];
}

class AucorsaCardMovements extends Equatable {
  final List<AucorsaCardMovement> movements;
  final bool hasNextPage;

  const AucorsaCardMovements({
    required this.movements,
    required this.hasNextPage,
  });

  @override
  List<Object> get props => [movements, hasNextPage];
}
