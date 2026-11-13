/// Where an order is in its life, read once from the API's status string.
/// Every screen and filter asks this instead of comparing strings, so they
/// all agree on what counts as cancelled, pending or finished.
enum OrderStatus {
  pending('Pending'),
  verification('Verification'),
  processing('Processing'),
  delivered('Delivered'),
  installments('Installments'),
  completed('Completed'),
  cancelled('Cancelled'),
  rejected('Rejected'),

  /// A value this build doesn't know; shown as the server sent it.
  unknown('');

  const OrderStatus(this.label);

  final String label;

  /// The API's value, in any case. "Varification" is how the server spells it.
  static OrderStatus parse(String status) => switch (status.trim().toLowerCase()) {
        'pending' => pending,
        'varification' || 'verification' => verification,
        'processing' => processing,
        'delivered' => delivered,
        'instalments' || 'installments' => installments,
        'completed' => completed,
        'cancelled' || 'canceled' => cancelled,
        'rejected' => rejected,
        _ => unknown,
      };

  /// Stopped before it finished.
  bool get isCancelled => this == cancelled || this == rejected;

  /// Waiting for Atomshop's checks; installments start after delivery.
  bool get isPending => this == pending || this == verification;

  bool get isClosed => isCancelled || this == completed;
}
