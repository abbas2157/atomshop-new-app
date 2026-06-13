/// Thrown when an API response indicates the seller's current plan does not
/// include the feature being accessed (requires_upgrade / requires_plan).
class SellerPlanUpgradeException implements Exception {
  final String message;
  final String messageUr;
  final String phone;

  const SellerPlanUpgradeException({
    required this.message,
    this.messageUr = '',
    this.phone = '+923302277522',
  });

  @override
  String toString() => message;
}
