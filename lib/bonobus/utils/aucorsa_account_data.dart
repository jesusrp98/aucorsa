import 'package:aucorsa/bonobus/cubits/aucorsa_movements_cubit.dart';
import 'package:aucorsa/bonobus/repositories/aucorsa_card_repository.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class AucorsaAccountData {
  static const _legacyCardsStorageKey = 'AucorsaCardsCubit';

  const AucorsaAccountData._();

  static Future<void> clear({
    required AucorsaCardRepository repository,
    String? cardNumber,
    Storage? storage,
  }) async {
    final effectiveStorage = storage ?? HydratedBloc.storage;
    await Future.wait([
      repository.clearAccountData(),
      effectiveStorage.delete(_legacyCardsStorageKey),
      if (cardNumber != null)
        effectiveStorage.delete(AucorsaMovementsCubit.storageKey(cardNumber)),
    ]);
  }
}
