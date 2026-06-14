import 'package:envied/envied.dart';

part 'env.dev.g.dart';

@Envied(path: '.env.development', obfuscate: true)
abstract class EnvDev {
  /// The value for Base Url.
  @EnviedField(varName: 'BASE_URL', obfuscate: true)
  static final String baseUrl = _EnvDev.baseUrl;
  /// The value for Google Maps Api Key.
  @EnviedField(varName: 'GOOGLE_MAPS_API_KEY', obfuscate: true)
  static final String googleMapsApiKey = _EnvDev.googleMapsApiKey;
  /// The value for Google Auth Android Client Id.
  @EnviedField(varName: 'GOOGLE_AUTH_ANDROID_CLIENT_ID', obfuscate: true)
  static final String googleAuthAndroidClientId = _EnvDev.googleAuthAndroidClientId;
  /// The value for Google Server Client Id.
  @EnviedField(varName: 'GOOGLE_SERVER_CLIENT_ID', obfuscate: true)
  static final String googleServerClientId = _EnvDev.googleServerClientId;
  /// The value for Data Encryption Key.
  @EnviedField(varName: 'DATA_ENCRYPTION_KEY', obfuscate: true)
  static final String dataEncryptionKey = _EnvDev.dataEncryptionKey;
  /// The value for Encryption Salt.
  @EnviedField(varName: 'ENCRYPTION_SALT', obfuscate: true)
  static final String encryptionSalt = _EnvDev.encryptionSalt;
  /// The value for Countries Url.
  @EnviedField(varName: 'COUNTRIES_URL', obfuscate: true)
  static final String countriesUrl = _EnvDev.countriesUrl;
  /// The value for Check Phone Url.
  @EnviedField(varName: 'CHECK_PHONE_URL', obfuscate: true)
  static final String checkPhoneUrl = _EnvDev.checkPhoneUrl;
  /// The value for Validate Otp Url.
  @EnviedField(varName: 'VALIDATE_OTP_URL', obfuscate: true)
  static final String validateOtpUrl = _EnvDev.validateOtpUrl;
  /// The value for Connection With Google Url.
  @EnviedField(varName: 'CONNECTION_WITH_GOOGLE_URL', obfuscate: true)
  static final String connectionWithGoogleUrl = _EnvDev.connectionWithGoogleUrl;
  /// The value for Complete Profile With Google Url.
  @EnviedField(varName: 'COMPLETE_PROFILE_WITH_GOOGLE_URL', obfuscate: true)
  static final String completeProfileWithGoogleUrl = _EnvDev.completeProfileWithGoogleUrl;
  /// The value for Account Recovery Request Url.
  @EnviedField(varName: 'ACCOUNT_RECOVERY_REQUEST_URL', obfuscate: true)
  static final String accountRecoveryRequestUrl = _EnvDev.accountRecoveryRequestUrl;
  /// The value for Account Recovery Url.
  @EnviedField(varName: 'ACCOUNT_RECOVERY_URL', obfuscate: true)
  static final String accountRecoveryUrl = _EnvDev.accountRecoveryUrl;
  /// The value for Refresh Token Url.
  @EnviedField(varName: 'REFRESH_TOKEN_URL', obfuscate: true)
  static final String refreshTokenUrl = _EnvDev.refreshTokenUrl;
  /// The value for Logout Url.
  @EnviedField(varName: 'LOGOUT_URL', obfuscate: true)
  static final String logoutUrl = _EnvDev.logoutUrl;
  /// The value for My Profile Url.
  @EnviedField(varName: 'MY_PROFILE_URL', obfuscate: true)
  static final String myProfileUrl = _EnvDev.myProfileUrl;
  /// The value for Complete User Profile Url.
  @EnviedField(varName: 'COMPLETE_USER_PROFILE_URL', obfuscate: true)
  static final String completeUserProfileUrl = _EnvDev.completeUserProfileUrl;
  /// The value for Update Driver Profile Url.
  @EnviedField(varName: 'UPDATE_DRIVER_PROFILE_URL', obfuscate: true)
  static final String updateDriverProfileUrl = _EnvDev.updateDriverProfileUrl;
  /// The value for Add Driver Document Url.
  @EnviedField(varName: 'ADD_DRIVER_DOCUMENT_URL', obfuscate: true)
  static final String addDriverDocumentUrl = _EnvDev.addDriverDocumentUrl;
  /// The value for Get Driver Profile Url.
  @EnviedField(varName: 'GET_DRIVER_PROFILE_URL', obfuscate: true)
  static final String getDriverProfileUrl = _EnvDev.getDriverProfileUrl;
  /// The value for Vehicle Categories Url.
  @EnviedField(varName: 'VEHICLE_CATEGORIES_URL', obfuscate: true)
  static final String vehicleCategoriesUrl = _EnvDev.vehicleCategoriesUrl;
  /// The value for Service Types Url.
  @EnviedField(varName: 'SERVICE_TYPES_URL', obfuscate: true)
  static final String serviceTypesUrl = _EnvDev.serviceTypesUrl;
  /// The value for Driver Vehicles Url.
  @EnviedField(varName: 'DRIVER_VEHICLES_URL', obfuscate: true)
  static final String driverVehiclesUrl = _EnvDev.driverVehiclesUrl;
  /// The value for Driver Active Vehicle Url.
  @EnviedField(varName: 'DRIVER_ACTIVE_VEHICLE_URL', obfuscate: true)
  static final String driverActiveVehicleUrl = _EnvDev.driverActiveVehicleUrl;
  /// The value for Available Trips Url.
  @EnviedField(varName: 'AVAILABLE_TRIPS_URL', obfuscate: true)
  static final String availableTripsUrl = _EnvDev.availableTripsUrl;
  /// The value for Driver Trips Url.
  @EnviedField(varName: 'DRIVER_TRIPS_URL', obfuscate: true)
  static final String driverTripsUrl = _EnvDev.driverTripsUrl;
  /// The value for Driver Trip Details Url.
  @EnviedField(varName: 'DRIVER_TRIP_DETAILS_URL', obfuscate: true)
  static final String driverTripDetailsUrl = _EnvDev.driverTripDetailsUrl;
  /// The value for Trip Status Url.
  @EnviedField(varName: 'TRIP_STATUS_URL', obfuscate: true)
  static final String tripStatusUrl = _EnvDev.tripStatusUrl;
  /// The value for Vehicle Info By Category Id Url.
  @EnviedField(varName: 'VEHICLE_INFO_BY_CATEGORY_ID_URL', obfuscate: true)
  static final String vehicleInfoByCategoryIdUrl = _EnvDev.vehicleInfoByCategoryIdUrl;
  /// The value for Upload Document Url.
  @EnviedField(varName: 'UPLOAD_DOCUMENT_URL', obfuscate: true)
  static final String uploadDocumentUrl = _EnvDev.uploadDocumentUrl;
  /// The value for Change Status Url.
  @EnviedField(varName: 'CHANGE_STATUS_URL', obfuscate: true)
  static final String changeStatusUrl = _EnvDev.changeStatusUrl;
  /// The value for Brands Url.
  @EnviedField(varName: 'BRANDS_URL', obfuscate: true)
  static final String brandsUrl = _EnvDev.brandsUrl;
  /// The value for Models Url.
  @EnviedField(varName: 'MODELS_URL', obfuscate: true)
  static final String modelsUrl = _EnvDev.modelsUrl;
  /// The value for Vehicle Colors Url.
  @EnviedField(varName: 'VEHICLE_COLORS_URL', obfuscate: true)
  static final String vehicleColorsUrl = _EnvDev.vehicleColorsUrl;
  /// The value for Seats Url.
  @EnviedField(varName: 'SEATS_URL', obfuscate: true)
  static final String seatsUrl = _EnvDev.seatsUrl;
  /// The value for Switch Role Url.
  @EnviedField(varName: 'SWITCH_ROLE_URL', obfuscate: true)
  static final String switchRoleUrl = _EnvDev.switchRoleUrl;
  /// The value for Vehicles Url.
  @EnviedField(varName: 'VEHICLES_URL', obfuscate: true)
  static final String vehiclesUrl = _EnvDev.vehiclesUrl;
  /// The value for Cloudinary Cloud Name.
  @EnviedField(varName: 'CLOUDINARY_CLOUD_NAME', obfuscate: true)
  static final String cloudinaryCloudName = _EnvDev.cloudinaryCloudName;
  /// The value for Cloudinary Upload Preset.
  @EnviedField(varName: 'CLOUDINARY_UPLOAD_PRESET', obfuscate: true)
  static final String cloudinaryUploadPreset = _EnvDev.cloudinaryUploadPreset;
  /// The value for Drivers Trips Url.
  @EnviedField(varName: 'DRIVERS_TRIPS_URL', obfuscate: true)
  static final String driversTripsUrl = _EnvDev.driversTripsUrl;
  /// The value for Accept Trip Url.
  @EnviedField(varName: 'ACCEPT_TRIP_URL', obfuscate: true)
  static final String acceptTripUrl = _EnvDev.acceptTripUrl;
  /// The value for Reject Trip Url.
  @EnviedField(varName: 'REJECT_TRIP_URL', obfuscate: true)
  static final String rejectTripUrl = _EnvDev.rejectTripUrl;
  /// The value for Arrived Url.
  @EnviedField(varName: 'ARRIVED_URL', obfuscate: true)
  static final String arrivedUrl = _EnvDev.arrivedUrl;
  /// The value for Start Url.
  @EnviedField(varName: 'START_URL', obfuscate: true)
  static final String startUrl = _EnvDev.startUrl;
  /// The value for Complete Url.
  @EnviedField(varName: 'COMPLETE_URL', obfuscate: true)
  static final String completeUrl = _EnvDev.completeUrl;
  /// The value for Cancel Url.
  @EnviedField(varName: 'CANCEL_URL', obfuscate: true)
  static final String cancelUrl = _EnvDev.cancelUrl;
  /// The value for Trips Url.
  @EnviedField(varName: 'TRIPS_URL', obfuscate: true)
  static final String tripsUrl = _EnvDev.tripsUrl;
  /// The value for Available Drivers Url.
  @EnviedField(varName: 'AVAILABLE_DRIVERS_URL', obfuscate: true)
  static final String availableDriversUrl = _EnvDev.availableDriversUrl;
  /// The value for Nearby Avaible Drivers Url.
  @EnviedField(varName: 'NEARBY_AVAIBLE_DRIVERS_URL', obfuscate: true)
  static final String nearbyAvaibleDriversUrl = _EnvDev.nearbyAvaibleDriversUrl;
  /// The value for Wallet Url.
  @EnviedField(varName: 'WALLET_URL', obfuscate: true)
  static final String walletUrl = _EnvDev.walletUrl;
  /// The value for Wallet Deposit Url.
  @EnviedField(varName: 'WALLET_DEPOSIT_URL', obfuscate: true)
  static final String walletDepositUrl = _EnvDev.walletDepositUrl;
  /// The value for Wallet Withdraw Url.
  @EnviedField(varName: 'WALLET_WITHDRAW_URL', obfuscate: true)
  static final String walletWithdrawUrl = _EnvDev.walletWithdrawUrl;
  /// The value for Wallet Transactions Url.
  @EnviedField(varName: 'WALLET_TRANSACTIONS_URL', obfuscate: true)
  static final String walletTransactionsUrl = _EnvDev.walletTransactionsUrl;
  /// The value for Payment Operators Url.
  @EnviedField(varName: 'PAYMENT_OPERATORS_URL', obfuscate: true)
  static final String paymentOperatorsUrl = _EnvDev.paymentOperatorsUrl;
  /// The value for Driver Earnings Url.
  @EnviedField(varName: 'DRIVER_EARNINGS_URL', obfuscate: true)
  static final String driverEarningsUrl = _EnvDev.driverEarningsUrl;
  /// The value for Notifications Url.
  @EnviedField(varName: 'NOTIFICATIONS_URL', obfuscate: true)
  static final String notificationsUrl = _EnvDev.notificationsUrl;
  /// The value for Notifications Unread Count Url.
  @EnviedField(varName: 'NOTIFICATIONS_UNREAD_COUNT_URL', obfuscate: true)
  static final String notificationsUnreadCountUrl = _EnvDev.notificationsUnreadCountUrl;
  /// The value for Driver Current Trip Url.
  @EnviedField(varName: 'DRIVER_CURRENT_TRIP_URL', obfuscate: true)
  static final String driverCurrentTripUrl = _EnvDev.driverCurrentTripUrl;
  /// The value for Add Device Token Url.
  @EnviedField(varName: 'ADD_DEVICE_TOKEN_URL', obfuscate: true)
  static final String addDeviceTokenUrl = _EnvDev.addDeviceTokenUrl;
  /// The value for Path Url.
  @EnviedField(varName: 'PATH_URL', obfuscate: true)
  static final String pathUrl = _EnvDev.pathUrl;
  /// The value for Driver Payouts Earnings Breakdown Url.
  @EnviedField(varName: 'DRIVER_PAYOUTS_EARNINGS_BREAKDOWN_URL', obfuscate: true)
  static final String driverPayoutsEarningsBreakdownUrl = _EnvDev.driverPayoutsEarningsBreakdownUrl;
  /// The value for Api Version Url.
  @EnviedField(varName: 'API_VERSION_URL', obfuscate: true)
  static final String apiVersionUrl = _EnvDev.apiVersionUrl;

}
