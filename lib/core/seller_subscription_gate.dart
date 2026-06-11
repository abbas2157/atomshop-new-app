/// Lightweight static gate that lets the network layer signal a subscription
/// block to the seller shell without creating a circular dependency between
/// core/network and features/seller.
///
/// The shell registers a listener in initState and clears it in dispose.
/// NetworkManager fires trigger() whenever any API response indicates the
/// seller's subscription is inactive or payment is under review.
class SellerSubscriptionGate {
  SellerSubscriptionGate._();

  static void Function(bool underReview)? _listener;

  static void setListener(void Function(bool underReview) fn) {
    _listener = fn;
  }

  static void clearListener() {
    _listener = null;
  }

  /// Called by NetworkManager. [underReview] is true when there is a pending
  /// payment waiting for admin confirmation, false when no plan exists at all.
  static void trigger(bool underReview) {
    _listener?.call(underReview);
  }
}
