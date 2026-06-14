import 'package:env/env.dart';

enum Flavor { development, production, staging }

sealed class AppEnv {
  const AppEnv();

  String getEnv(Env env);
}

class AppFlavor extends AppEnv {
  factory AppFlavor.development() => const AppFlavor._(flavor: Flavor.development);

factory AppFlavor.production() => const AppFlavor._(flavor: Flavor.production);

factory AppFlavor.staging() => const AppFlavor._(flavor: Flavor.staging);


  const AppFlavor._({required this.flavor});

  final Flavor flavor;

  @override
  String getEnv(Env env) => switch(env){
      Env.appName => switch(flavor){
    Flavor.development => EnvDev.appName,

  Flavor.production => EnvProd.appName,

  Flavor.staging => EnvStg.appName,

},

  Env.appSuffix => switch(flavor){
    Flavor.development => EnvDev.appSuffix,

  Flavor.production => EnvProd.appSuffix,

  Flavor.staging => EnvStg.appSuffix,

},

  Env.baseUrl => switch(flavor){
    Flavor.development => EnvDev.baseUrl,

  Flavor.production => EnvProd.baseUrl,

  Flavor.staging => EnvStg.baseUrl,

},

  Env.encryptionKey => switch(flavor){
    Flavor.development => EnvDev.encryptionKey,

  Flavor.production => EnvProd.encryptionKey,

  Flavor.staging => EnvStg.encryptionKey,

},

  };
}
