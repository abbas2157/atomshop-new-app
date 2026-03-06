import 'package:atompro/features/city_area_selector/viewmodel/city_area_viewmodel.dart';
import 'package:atompro/features/smart_seller/repository/smart_seller_repo.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'smart_seller_viewmodel.g.dart';

// ── State ──────────────────────────────────────────────────────────────────

class SmartSellerState {
  // Step 1
  final String name;
  final String email;
  final String phone;
  final String whatsappPhone;
  final String password;
  final String businessName;

  // Step 2
  final String cnicNumber; // string — sent as-is
  final String businessType;
  final String ntnTax;
  final String investmentCapacity;

  // Step 3 — city/area from CityAreaViewModel, address here
  final String address;

  // Step 4
  final String businessRegistrationNumber;

  // UI
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final String? successCode; // "ATOM-SELL-6068"
  final String? successMessage;

  const SmartSellerState({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.whatsappPhone = '',
    this.password = '',
    this.businessName = '',
    this.cnicNumber = '',
    this.businessType = '',
    this.ntnTax = '',
    this.investmentCapacity = '',
    this.address = '',
    this.businessRegistrationNumber = '',
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.successCode,
    this.successMessage,
  });

  SmartSellerState copyWith({
    String? name,
    String? email,
    String? phone,
    String? whatsappPhone,
    String? password,
    String? businessName,
    String? cnicNumber,
    String? businessType,
    String? ntnTax,
    String? investmentCapacity,
    String? address,
    String? businessRegistrationNumber,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    String? successCode,
    String? successMessage,
    bool clearError = false,
  }) {
    return SmartSellerState(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      whatsappPhone: whatsappPhone ?? this.whatsappPhone,
      password: password ?? this.password,
      businessName: businessName ?? this.businessName,
      cnicNumber: cnicNumber ?? this.cnicNumber,
      businessType: businessType ?? this.businessType,
      ntnTax: ntnTax ?? this.ntnTax,
      investmentCapacity: investmentCapacity ?? this.investmentCapacity,
      address: address ?? this.address,
      businessRegistrationNumber:
          businessRegistrationNumber ?? this.businessRegistrationNumber,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successCode: successCode ?? this.successCode,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

// ── Viewmodel ──────────────────────────────────────────────────────────────

@riverpod
class SmartSellerViewmodel extends _$SmartSellerViewmodel {
  @override
  SmartSellerState build() => const SmartSellerState();

  // ── Field updates ─────────────────────────────────────────────────────────

  void updateName(String v) =>
      state = state.copyWith(name: v, clearError: true);
  void updateEmail(String v) =>
      state = state.copyWith(email: v, clearError: true);
  void updatePhone(String v) =>
      state = state.copyWith(phone: v, clearError: true);
  void updateWhatsapp(String v) =>
      state = state.copyWith(whatsappPhone: v, clearError: true);
  void updatePassword(String v) =>
      state = state.copyWith(password: v, clearError: true);
  void updateBusinessName(String v) =>
      state = state.copyWith(businessName: v, clearError: true);
  void updateCnic(String v) =>
      state = state.copyWith(cnicNumber: v, clearError: true);
  void updateBusinessType(String? v) =>
      state = state.copyWith(businessType: v ?? '', clearError: true);
  void updateNtn(String v) =>
      state = state.copyWith(ntnTax: v, clearError: true);
  void updateInvestment(String? v) =>
      state = state.copyWith(investmentCapacity: v ?? '', clearError: true);
  void updateAddress(String v) =>
      state = state.copyWith(address: v, clearError: true);
  void updateRegNumber(String v) =>
      state = state.copyWith(businessRegistrationNumber: v, clearError: true);

  void clearError() => state = state.copyWith(clearError: true);

  // ── Per-step validation (called by view before advancing) ─────────────────

  /// Returns an error string, or null if valid.
  String? validateStep(int step) {
    switch (step) {
      case 0:
        if (state.name.trim().isEmpty) return 'Full name is required';
        if (state.businessName.trim().isEmpty) {
          return 'Business name is required';
        }
        if (state.phone.trim().isEmpty) return 'Phone number is required';
        if (state.email.trim().isEmpty) return 'Email address is required';
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(state.email.trim())) {
          return 'Enter a valid email address';
        }
        if (state.password.length < 8) {
          return 'Password must be at least 8 characters';
        }
        return null;

      case 1:
        if (state.cnicNumber.trim().isEmpty) return 'CNIC number is required';
        if (state.businessType.isEmpty) return 'Please select a business type';
        return null;

      case 2:
        final cityArea = ref.read(cityAreaViewModelProvider);
        if (cityArea.selectedCity == null) return 'Please select your city';
        if (cityArea.selectedArea == null) return 'Please select your area';
        if (state.address.trim().isEmpty) return 'Complete address is required';
        return null;

      case 3:
        // Nothing required on step 4 (reg number / NTN optional)
        return null;

      default:
        return null;
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> submit() async {
    print("api called");
    final cityArea = ref.read(cityAreaViewModelProvider);

    if (cityArea.selectedCity == null || cityArea.selectedArea == null) {
      state = state.copyWith(errorMessage: 'Please select city and area');
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final data = <String, dynamic>{
        'name': state.name.trim(),
        'email': state.email.trim(),
        'phone': state.phone.trim(),
        // If whatsapp not filled, fall back to phone
        'whatsapp_phone': state.whatsappPhone.trim().isEmpty
            ? state.phone.trim()
            : state.whatsappPhone.trim(),
        'password': state.password,
        'business_name': state.businessName.trim(),
        'business_type': state.businessType,
        'cnic_number': state.cnicNumber.trim(),
        'ntn_tax': state.ntnTax.trim(),
        'investment_capacity': state.investmentCapacity.trim(),
        'business_registration_number': state.businessRegistrationNumber.trim(),
        'address': state.address.trim(),
        'city_id': cityArea.selectedCity!.id,
        'area_id': cityArea.selectedArea!.id,
        'fulfillment': 'Seller',
      };

      print(data);

      final response = await ref.read(smartSellerRepoProvider).submit(data);
      print(response);
      if (response['success'] == true) {
        final d = (response['data'] as Map<String, dynamic>? ?? {});
        state = state.copyWith(
          isSubmitting: false,
          isSuccess: true,
          successCode: d['code'] as String?,
          successMessage: response['message'] as String?,
        );
      } else {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: _parseErrorResponse(response),
        );
      }
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _parseException(e),
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Flattens {"email": ["The email has already been taken."]} → first message.
  String _parseErrorResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map && data.isNotEmpty) {
      for (final messages in data.values) {
        if (messages is List && messages.isNotEmpty) {
          return messages.first.toString();
        }
      }
    }
    return response['message'] as String? ?? 'Something went wrong.';
  }

  String _parseException(dynamic e) {
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('NetworkException')) {
      return 'No internet connection. Please check your network.';
    }
    if (s.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }
    if (s.contains('500') || s.contains('502')) {
      return 'Server error. Please try again later.';
    }
    if (s.contains('401') || s.contains('403')) {
      return 'Session expired. Please log in again.';
    }
    return 'Something went wrong. Please try again.';
  }

  void reset() => state = const SmartSellerState();
}
