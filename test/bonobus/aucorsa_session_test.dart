import 'package:aucorsa/bonobus/utils/aucorsa_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

void main() {
  late _MemoryStorage storage;

  setUp(() => storage = _MemoryStorage());

  test('reads back the header it was given', () async {
    await AucorsaSession.save('wordpress_logged_in=token', storage);

    expect(AucorsaSession.read(storage), 'wordpress_logged_in=token');
  });

  test('has nothing to offer before the first sign in', () {
    expect(AucorsaSession.read(storage), isEmpty);
  });

  test('keeps the stored session when the jar comes back empty', () async {
    await AucorsaSession.save('wordpress_logged_in=token', storage);

    // What a signed-out web view would hand over. Overwriting with it would
    // throw away the only copy that survives a restart.
    await AucorsaSession.save('', storage);

    expect(AucorsaSession.read(storage), 'wordpress_logged_in=token');
  });

  test('ignores a stored value written in another shape', () async {
    await storage.write(AucorsaSession.storageKey, 'wordpress_logged_in=token');

    expect(AucorsaSession.read(storage), isEmpty);
  });

  test('ignores a stored entry that lost its cookie', () async {
    await storage.write(AucorsaSession.storageKey, {'cookie': null});

    expect(AucorsaSession.read(storage), isEmpty);
  });

  test('clear leaves nothing behind', () async {
    await AucorsaSession.save('wordpress_logged_in=token', storage);

    await AucorsaSession.clear(storage);

    expect(AucorsaSession.read(storage), isEmpty);
    expect(storage.read(AucorsaSession.storageKey), isNull);
  });

  test('falls back to the shared storage when none is given', () async {
    HydratedBloc.storage = storage;

    await AucorsaSession.save('wordpress_logged_in=token');

    expect(AucorsaSession.read(), 'wordpress_logged_in=token');
    expect(storage.read(AucorsaSession.storageKey), isNotNull);
  });
}

class _MemoryStorage implements Storage {
  final Map<String, dynamic> _values = {};

  @override
  dynamic read(String key) => _values[key];

  @override
  Future<void> write(String key, dynamic value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> clear() async => _values.clear();

  @override
  Future<void> close() async {}
}
