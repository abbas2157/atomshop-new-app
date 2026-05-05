enum AppMode {
  customer,
  seller;

  String get storageValue {
    switch (this) {
      case AppMode.customer:
        return 'customer';
      case AppMode.seller:
        return 'seller';
    }
  }

  String get label {
    switch (this) {
      case AppMode.customer:
        return 'Customer mode';
      case AppMode.seller:
        return 'Seller mode';
    }
  }

  static AppMode fromStorage(String? value) {
    switch (value) {
      case 'seller':
        return AppMode.seller;
      case 'customer':
      default:
        return AppMode.customer;
    }
  }
}
