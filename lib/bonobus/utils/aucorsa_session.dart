import 'package:hydrated_bloc/hydrated_bloc.dart';

/// Our own copy of the cookies that keep the user signed in to AUCORSA.
///
/// The web view jar is not a dependable home for them. The site hands out
/// cookies that only live as long as the process, and how long a jar keeps
/// them differs per platform and per system web view version. Since the
/// movement requests are plain HTTP calls rather than web view navigations,
/// keeping the `Cookie` header next to the rest of the stored app state is
/// what actually makes a sign-in outlive a restart.
///
/// The value is an authentication token: it is written to the same on-device
/// storage as the other cubits, readable by anything that can already read the
/// app sandbox.
class AucorsaSession {
  static const storageKey = 'AucorsaSession';

  const AucorsaSession._();

  /// The stored `Cookie` header, or an empty string when there is none.
  static String read([Storage? storage]) {
    final stored = (storage ?? HydratedBloc.storage).read(storageKey);

    return stored is Map && stored['cookie'] is String
        ? stored['cookie'] as String
        : '';
  }

  static Future<void> save(String cookieHeader, [Storage? storage]) async {
    if (cookieHeader.isEmpty) return;

    await (storage ?? HydratedBloc.storage).write(storageKey, {
      'cookie': cookieHeader,
    });
  }

  static Future<void> clear([Storage? storage]) =>
      (storage ?? HydratedBloc.storage).delete(storageKey);
}
