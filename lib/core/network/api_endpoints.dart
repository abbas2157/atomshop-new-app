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
  static const String sellerLogin = "seller-app/login";
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
  static const String sellerCustomerCities = "seller-app/customers/areas";
  static const String cities = "cities";
  static String areasByCity(int cityId) => "areas/$cityId";
  static const String placeCustomOrder = "custom-order/create";
  static const String updateProfile = "account/profile/update";
  static const String customerProfileUpload = "account/profile/upload";
  static String customerProfile(String uuid) => "account/profile/$uuid";

  /// seller app endpoints
  static const String sellerLogout = "seller-app/logout";
  static const String sellerDashboard = "seller-app/dashboard";
  static const String sellerSalesRevenue = "seller-app/sales-revenue";
  static const String sellerProfile = "seller-app/profile";
  static const String sellerProfileUpdate = "seller-app/profile/update";
  static const String sellerProfilePictureUpdate =
      "seller-app/profile/picture/update";
  static const String sellerChangePassword =
      "seller-app/profile/change/password";
  static const String sellerInfo = "seller-app/profile/seller-info";
  static const String sellerBusinessInfo = "seller-app/profile/business-info";
  static const String sellerCustomers = "seller-app/customers";
  static const String sellerMyCustomers = "seller-app/customers/my";
  static const String sellerOtherCustomers = "seller-app/customers/other";
  static const String sellerStoreCustomer = "seller-app/customers/store";
  static const String sellerCustomersNotificationCount =
      "seller-app/customers/notification-count";
  static const String sellerOrders = "seller-app/orders";
  static const String sellerStoreOrder = "seller-app/orders/store";
  static const String sellerCustomOrders = "seller-app/custom-orders";
  static const String sellerStoreCustomOrder = "seller-app/custom-orders/store";
  static const String sellerCustomOrdersPendingCount =
      "seller-app/custom-orders/pending-count";
  static const String sellerCustomOrdersStatusCounts =
      "seller-app/custom-orders/status-counts";
  static const String sellerInstalments = "seller-app/instalment";
  static const String sellerPayInstalment = "seller-app/instalment/pay";
  static const String sellerInstalmentsTopupPdf =
      "seller-app/instalment/topup-pdf/download";
  static const String sellerLeads = "seller-app/leads";
  static const String sellerOtherLeads = "seller-app/leads/others";
  static const String sellerLeadStatusCounts = "seller-app/leads/status-counts";
  static const String sellerOtherLeadStatusCounts =
      "seller-app/leads/others-status-counts";
  static const String sellerNewLeadsCount = "seller-app/leads/count";
  static const String sellerSalesTeam = "seller-app/sales-team";
  static const String sellerStoreSalesTeamMember =
      "seller-app/sales-team/store";
  static const String sellerFeeCharge = "seller-app/fee-charge";
  static const String sellerPayFeeCharge = "seller-app/fee-charge/pay";
  static const String sellerInvestments = "seller-app/investments";
  static const String sellerSubscription = "seller-app/subscription";
  static const String sellerSubscriptionPay = "seller-app/subscription/pay";

  static String sellerInvestmentDetails(int investmentId) =>
      "seller-app/investments/$investmentId";

  static String sellerInvestmentStatus(int investmentId) =>
      "seller-app/investments/$investmentId/status";

  static String sellerOrderDetails(String orderUuid) =>
      "seller-app/orders/show/$orderUuid";

  static String sellerOrderStatus(String orderUuid) =>
      "seller-app/orders/status/$orderUuid";

  static String sellerOrderPdf(String orderUuid) =>
      "seller-app/orders/pdf/$orderUuid";

  static String sellerCustomerProfile(String customerUuid) =>
      "seller-app/customers/$customerUuid/profile";

  static String sellerCustomerUpdate(String customerUuid) =>
      "seller-app/customers/$customerUuid/update";

  static String sellerCustomerInstalments(String customerUuid) =>
      "seller-app/customers/$customerUuid/instalment";

  static String sellerCustomerCustomOrders(String customerUuid) =>
      "seller-app/customers/$customerUuid/custom-orders";

  static String sellerCustomerAreasByCity(int cityId) =>
      "seller-app/customers/areas?city_id=$cityId";

  static String sellerInstalmentOrderDetail(int orderId) =>
      "seller-app/instalment/order/$orderId";

  static String sellerInstalmentInvoiceData(int instalmentId) =>
      "seller-app/instalment/invoice/$instalmentId/data";

  static String sellerLeadUpdate(int leadId) =>
      "seller-app/leads/update/$leadId";

  static String sellerLeadCustomOrder(int leadId) =>
      "seller-app/leads/custom-order/$leadId";

  static String sellerSalesTeamEdit(String memberUuid) =>
      "seller-app/sales-team/$memberUuid/edit";

  static String sellerSalesTeamUpdate(String memberUuid) =>
      "seller-app/sales-team/$memberUuid/update";

  static String sellerSalesTeamPerformance(String memberUuid) =>
      "seller-app/sales-team/$memberUuid/performance";

  static String sellerCustomOrderDetails(String orderUuid) =>
      "seller-app/custom-orders/show/$orderUuid";

  static String sellerCustomOrderStatus(String orderUuid) =>
      "seller-app/custom-orders/status/$orderUuid";

  static String sellerCustomOrderPdf(String orderUuid) =>
      "seller-app/custom-orders/$orderUuid/pdf";

  static String sellerCustomOrderCloseDeal(String orderUuid) =>
      "seller-app/custom-orders/close-deal/$orderUuid";

  static String sellerCustomOrderGuarantor(String orderUuid) =>
      "seller-app/custom-orders/guarantor/$orderUuid";

  static const String sellerWebsiteOrders = "seller-app/website-orders";

  // ── Seller reports ─────────────────────────────────────────────────────
  static const String sellerReportsCustomers =
      'seller-app/reports/customers';
  static const String sellerReportsRecoverySheet =
      'seller-app/reports/recovery-sheet';
  static const String sellerReportsCustomerLedger =
      'seller-app/reports/customer-ledger';
  static const String sellerReportsAging =
      'seller-app/reports/aging';
  static const String sellerReportsUpcomingDues =
      'seller-app/reports/upcoming-dues';
  static const String sellerReportsDefaulters =
      'seller-app/reports/defaulters';
  static const String sellerReportsCollection =
      'seller-app/reports/collection';
  static const String sellerReportsSalesRevenue =
      'seller-app/reports/sales-revenue';
  static const String sellerReportsOrderSummary =
      'seller-app/reports/order-summary';
  static const String sellerReportsLeadFunnel =
      'seller-app/reports/lead-funnel';
  static const String sellerReportsOffersReport =
      'seller-app/reports/offers-report';
  static const String sellerReportsOutstanding =
      'seller-app/reports/outstanding';
  static const String sellerReportsPaymentHistory =
      'seller-app/reports/payment-history';

  // ── Customer notifications ──────────────────────────────────────────────
  static const String customerNotifications = 'notifications';
  static const String customerNotificationsCount = 'notifications/count';
  static String customerNotificationRead(int id) => 'notifications/$id/read';
  static const String customerNotificationsReadAll = 'notifications/read-all';

  // ── Seller notifications ────────────────────────────────────────────────
  static const String sellerNotifications = 'seller-app/notifications';
  static const String sellerNotificationsCount = 'seller-app/notifications/count';
  static String sellerNotificationRead(int id) => 'seller-app/notifications/$id/read';
  static const String sellerNotificationsReadAll = 'seller-app/notifications/read-all';

  // ── Seller notification settings ────────────────────────────────────────
  static const String sellerNotificationSettings =
      'seller-app/settings/notifications';
  static const String sellerNotificationSettingsToggle =
      'seller-app/settings/notifications/toggle';
}
