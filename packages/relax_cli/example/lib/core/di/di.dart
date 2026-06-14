import 'package:env/env.dart';
import 'package:get_it/get_it.dart';
import 'package:example/core/cache/cached_storage.dart';
import 'package:relax_storage/relax_storage.dart';

final getIt = GetIt.instance;

Future<void> setUpRegister(EnvValue env) async {
  await RelaxStorage.init();
  final cachedStorage = CachedStorage(env);

  getIt.registerSingleton<EnvValue>(env);
  getIt.registerSingleton<CachedStorage>(cachedStorage);

  // Register your repositories and services here, for example:
  // getIt.registerLazySingleton<AuthRepository>(
  //   () => AuthRepositoryImpl(env: env),
  // );
}
