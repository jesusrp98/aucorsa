import 'package:hydrated_bloc/hydrated_bloc.dart';

class FavoriteStopsCubit extends HydratedCubit<List<int>> {
  FavoriteStopsCubit() : super([]);

  bool isFavorite(int stopId) => state.contains(stopId);

  void add(int stopId) => emit([...state, stopId]);

  void remove(int stopId) =>
      emit(state.where((element) => element != stopId).toList());

  void toggle(int stopId) {
    if (isFavorite(stopId)) {
      return remove(stopId);
    }

    return add(stopId);
  }

  @override
  List<int> fromJson(Map<String, dynamic> json) =>
      (json['stops'] as List).cast<int>();

  @override
  Map<String, dynamic> toJson(List<int> state) => {'stops': state};
}
