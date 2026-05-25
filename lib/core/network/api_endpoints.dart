class ApiEndpoints {
  static const String baseUrl = "https://atomshop.pk/api/";

  /// endpoints
  static const String login = "account/login";
  static const String sellerLogin = "seller-app/login";
  static const String signup = "account/create";
  static const String deleteAccount = "account/delete/";
  static const String verifyOTP = "account/send/code/verify";
  static const String sendOTP = "account/send/code";
  static const String setPassword = "account/send/code/reset/password";
  static const String categories = "categories";
  static const String placeCustomOrder = "custom-order/create";
  static const String updateProfile = "account/profile/update";

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
  static const String sellerImportCustomers = "seller-app/customers/import";
  static const String sellerCustomersImportSample =
      "seller-app/customers/import/sample";
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
      "seller-app/instalment/topup-pdf";
  static const String sellerLeads = "seller-app/leads";
  static const String sellerOtherLeads = "seller-app/leads/others";
  static const String sellerLeadStatusCounts = "seller-app/leads/status-counts";
  static const String sellerOtherLeadStatusCounts =
      "seller-app/leads/others-status-counts";
  static const String sellerNewLeadsCount = "seller-app/leads/count";
  static const String sellerImportLeads = "seller-app/leads/import";
  static const String sellerLeadsSample = "seller-app/leads/sample";
  static const String sellerSalesTeam = "seller-app/sales-team";
  static const String sellerStoreSalesTeamMember =
      "seller-app/sales-team/store";
  static const String sellerFeeCharge = "seller-app/fee-charge";
  static const String sellerPayFeeCharge = "seller-app/fee-charge/pay";
  static const String sellerInvestments = "seller-app/investments";

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

  static String sellerCustomerInstalments(String customerUuid) =>
      "seller-app/customers/$customerUuid/instalment";

  static String sellerCustomerCustomOrders(String customerUuid) =>
      "seller-app/customers/$customerUuid/custom-orders";

  static String sellerCustomerAreasByCity(int cityId) =>
      "seller-app/customers/areas?city_id=$cityId";

  static String sellerInstalmentsExport({String? status}) {
    final suffix = status == null || status.isEmpty ? "" : "?status=$status";
    return "seller-app/instalment/export$suffix";
  }

  static String sellerInstalmentInvoice(String orderUuid) =>
      "seller-app/instalment/invoice/$orderUuid";

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
}
