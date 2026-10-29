class ApiEndpoints {
  static const String baseUrl = "https://atomshop.pk/api/";

  /// Base for stored public assets (uploaded images, receipts, etc.).
  static const String assetBaseUrl = "https://atomshop.pk/public/";

  /// Resolves a stored relative path (e.g. `images/customers/x.jpg`) to a full
  /// URL under `assetBaseUrl`. Returns '' for empty/placeholder values, and
  /// passes through values that are already absolute URLs.
  static String publicAsset(String? path) {
    final p = path?.trim() ?? '';
    if (p.isEmpty || p == 'Not available' || p == 'No image' || p == 'null') {
      return '';
    }
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    return '$assetBaseUrl${p.startsWith('/') ? p.substring(1) : p}';
  }

  /// endpoints
  static const String login = "account/login";
  static const String signup = "account/create";
  static const String deleteAccount = "account/delete/";
  static const String verifyOTP = "account/send/code/verify";
  static const String sendOTP = "account/send/code";
  static const String setPassword = "account/send/code/reset/password";
  static const String fcmStore = "fcm/store";
  static const String fcmAttachUser = "fcm/attach-user";
  static const String fcmLogout = "fcm/logout";
  static const String categories = "categories";
  static const String brands = "brands";
  static const String cities = "cities";
  static String areasByCity(int cityId) => "areas/$cityId";
  static const String placeCustomOrder = "custom-order/create";
  static const String updateProfile = "account/profile/update";
  static const String customerProfileUpload = "account/profile/upload";
  static String customerProfile(String uuid) => "account/profile/$uuid";

  // ── Customer notifications ──────────────────────────────────────────────
  static const String customerNotifications = 'notifications';
  static const String customerNotificationsCount = 'notifications/count';
  static String customerNotificationRead(int id) => 'notifications/$id/read';
  static const String customerNotificationsReadAll = 'notifications/read-all';
}
