import 'package:flutter_bloc/flutter_bloc.dart';

class BusLineSelectorCubit extends Cubit<String?> {
  BusLineSelectorCubit() : super(null);

  void selectBusLine(String? lineId) => emit(lineId);

  void clear() => emit(null);
}
