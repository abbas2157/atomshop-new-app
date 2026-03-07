class ApiEndpoints {
  static const String baseUrl = "https://atomshop.pk/api/";

  /// endpoints
  static const String login = "account/login";
  static const String signup = "account/create";
  static const String deleteAccount = "account/delete/";
  static const String verifyOTP = "account/send/code/verify";
  static const String sendOTP = "account/send/code";
  static const String setPassword = "account/send/code/reset/password";
  static const String categories = "categories";
  static const String placeCustomOrder = "custom-order/create";
  static const String updateProfile = "account/profile/update";
}
