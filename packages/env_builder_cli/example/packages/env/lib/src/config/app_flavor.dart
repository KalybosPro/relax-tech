import 'package:env/env.dart';

enum Flavor { development }

sealed class AppEnv {
  const AppEnv();

  String getEnv(Env env);
}

class AppFlavor extends AppEnv {
  factory AppFlavor.development() => const AppFlavor._(flavor: Flavor.development);


  const AppFlavor._({required this.flavor});

  final Flavor flavor;

  @override
  String getEnv(Env env) => switch(env){
      Env.baseUrl => switch(flavor){
    Flavor.development => EnvDev.baseUrl,

},

  Env.googleMapsApiKey => switch(flavor){
    Flavor.development => EnvDev.googleMapsApiKey,

},

  Env.googleAuthAndroidClientId => switch(flavor){
    Flavor.development => EnvDev.googleAuthAndroidClientId,

},

  Env.googleServerClientId => switch(flavor){
    Flavor.development => EnvDev.googleServerClientId,

},

  Env.dataEncryptionKey => switch(flavor){
    Flavor.development => EnvDev.dataEncryptionKey,

},

  Env.encryptionSalt => switch(flavor){
    Flavor.development => EnvDev.encryptionSalt,

},

  Env.countriesUrl => switch(flavor){
    Flavor.development => EnvDev.countriesUrl,

},

  Env.checkPhoneUrl => switch(flavor){
    Flavor.development => EnvDev.checkPhoneUrl,

},

  Env.validateOtpUrl => switch(flavor){
    Flavor.development => EnvDev.validateOtpUrl,

},

  Env.connectionWithGoogleUrl => switch(flavor){
    Flavor.development => EnvDev.connectionWithGoogleUrl,

},

  Env.completeProfileWithGoogleUrl => switch(flavor){
    Flavor.development => EnvDev.completeProfileWithGoogleUrl,

},

  Env.accountRecoveryRequestUrl => switch(flavor){
    Flavor.development => EnvDev.accountRecoveryRequestUrl,

},

  Env.accountRecoveryUrl => switch(flavor){
    Flavor.development => EnvDev.accountRecoveryUrl,

},

  Env.refreshTokenUrl => switch(flavor){
    Flavor.development => EnvDev.refreshTokenUrl,

},

  Env.logoutUrl => switch(flavor){
    Flavor.development => EnvDev.logoutUrl,

},

  Env.myProfileUrl => switch(flavor){
    Flavor.development => EnvDev.myProfileUrl,

},

  Env.completeUserProfileUrl => switch(flavor){
    Flavor.development => EnvDev.completeUserProfileUrl,

},

  Env.updateDriverProfileUrl => switch(flavor){
    Flavor.development => EnvDev.updateDriverProfileUrl,

},

  Env.addDriverDocumentUrl => switch(flavor){
    Flavor.development => EnvDev.addDriverDocumentUrl,

},

  Env.getDriverProfileUrl => switch(flavor){
    Flavor.development => EnvDev.getDriverProfileUrl,

},

  Env.vehicleCategoriesUrl => switch(flavor){
    Flavor.development => EnvDev.vehicleCategoriesUrl,

},

  Env.serviceTypesUrl => switch(flavor){
    Flavor.development => EnvDev.serviceTypesUrl,

},

  Env.driverVehiclesUrl => switch(flavor){
    Flavor.development => EnvDev.driverVehiclesUrl,

},

  Env.driverActiveVehicleUrl => switch(flavor){
    Flavor.development => EnvDev.driverActiveVehicleUrl,

},

  Env.availableTripsUrl => switch(flavor){
    Flavor.development => EnvDev.availableTripsUrl,

},

  Env.driverTripsUrl => switch(flavor){
    Flavor.development => EnvDev.driverTripsUrl,

},

  Env.driverTripDetailsUrl => switch(flavor){
    Flavor.development => EnvDev.driverTripDetailsUrl,

},

  Env.tripStatusUrl => switch(flavor){
    Flavor.development => EnvDev.tripStatusUrl,

},

  Env.vehicleInfoByCategoryIdUrl => switch(flavor){
    Flavor.development => EnvDev.vehicleInfoByCategoryIdUrl,

},

  Env.uploadDocumentUrl => switch(flavor){
    Flavor.development => EnvDev.uploadDocumentUrl,

},

  Env.changeStatusUrl => switch(flavor){
    Flavor.development => EnvDev.changeStatusUrl,

},

  Env.brandsUrl => switch(flavor){
    Flavor.development => EnvDev.brandsUrl,

},

  Env.modelsUrl => switch(flavor){
    Flavor.development => EnvDev.modelsUrl,

},

  Env.vehicleColorsUrl => switch(flavor){
    Flavor.development => EnvDev.vehicleColorsUrl,

},

  Env.seatsUrl => switch(flavor){
    Flavor.development => EnvDev.seatsUrl,

},

  Env.switchRoleUrl => switch(flavor){
    Flavor.development => EnvDev.switchRoleUrl,

},

  Env.vehiclesUrl => switch(flavor){
    Flavor.development => EnvDev.vehiclesUrl,

},

  Env.cloudinaryCloudName => switch(flavor){
    Flavor.development => EnvDev.cloudinaryCloudName,

},

  Env.cloudinaryUploadPreset => switch(flavor){
    Flavor.development => EnvDev.cloudinaryUploadPreset,

},

  Env.driversTripsUrl => switch(flavor){
    Flavor.development => EnvDev.driversTripsUrl,

},

  Env.acceptTripUrl => switch(flavor){
    Flavor.development => EnvDev.acceptTripUrl,

},

  Env.rejectTripUrl => switch(flavor){
    Flavor.development => EnvDev.rejectTripUrl,

},

  Env.arrivedUrl => switch(flavor){
    Flavor.development => EnvDev.arrivedUrl,

},

  Env.startUrl => switch(flavor){
    Flavor.development => EnvDev.startUrl,

},

  Env.completeUrl => switch(flavor){
    Flavor.development => EnvDev.completeUrl,

},

  Env.cancelUrl => switch(flavor){
    Flavor.development => EnvDev.cancelUrl,

},

  Env.tripsUrl => switch(flavor){
    Flavor.development => EnvDev.tripsUrl,

},

  Env.availableDriversUrl => switch(flavor){
    Flavor.development => EnvDev.availableDriversUrl,

},

  Env.nearbyAvaibleDriversUrl => switch(flavor){
    Flavor.development => EnvDev.nearbyAvaibleDriversUrl,

},

  Env.walletUrl => switch(flavor){
    Flavor.development => EnvDev.walletUrl,

},

  Env.walletDepositUrl => switch(flavor){
    Flavor.development => EnvDev.walletDepositUrl,

},

  Env.walletWithdrawUrl => switch(flavor){
    Flavor.development => EnvDev.walletWithdrawUrl,

},

  Env.walletTransactionsUrl => switch(flavor){
    Flavor.development => EnvDev.walletTransactionsUrl,

},

  Env.paymentOperatorsUrl => switch(flavor){
    Flavor.development => EnvDev.paymentOperatorsUrl,

},

  Env.driverEarningsUrl => switch(flavor){
    Flavor.development => EnvDev.driverEarningsUrl,

},

  Env.notificationsUrl => switch(flavor){
    Flavor.development => EnvDev.notificationsUrl,

},

  Env.notificationsUnreadCountUrl => switch(flavor){
    Flavor.development => EnvDev.notificationsUnreadCountUrl,

},

  Env.driverCurrentTripUrl => switch(flavor){
    Flavor.development => EnvDev.driverCurrentTripUrl,

},

  Env.addDeviceTokenUrl => switch(flavor){
    Flavor.development => EnvDev.addDeviceTokenUrl,

},

  Env.pathUrl => switch(flavor){
    Flavor.development => EnvDev.pathUrl,

},

  Env.driverPayoutsEarningsBreakdownUrl => switch(flavor){
    Flavor.development => EnvDev.driverPayoutsEarningsBreakdownUrl,

},

  Env.apiVersionUrl => switch(flavor){
    Flavor.development => EnvDev.apiVersionUrl,

},

  };
}
