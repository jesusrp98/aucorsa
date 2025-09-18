import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'bonobus_state.dart';

class BonobusCubit extends HydratedCubit<BonobusState> {
  BonobusCubit() : super(const BonobusState());

  void loading() => emit(state.copyWith(status: BonobusStatus.loading));

  void loaded({String? balance, String? name}) => emit(
    state.copyWith(
      balance: balance,
      name: name,
      status: BonobusStatus.loaded,
      lastUpdated: DateTime.now(),
    ),
  );

  void set({BonobusProvider? provider, String? id}) => emit(
    state.copyWith(
      provider: provider,
      id: id,
    ),
  );

  void reset() => emit(const BonobusState());

  @override
  BonobusState? fromJson(Map<String, dynamic> json) =>
      BonobusState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(BonobusState state) => state.toJson();
}
