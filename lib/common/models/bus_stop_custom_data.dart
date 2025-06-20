import 'package:equatable/equatable.dart';

class BusStopCustomData extends Equatable {
  final String? name;
  final int? icon;

  const BusStopCustomData({this.name, this.icon});

  @override
  List<Object?> get props => [name, icon];
}
