import 'dart:async';
import 'package:atompro/core/auth/session_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:atompro/features/custom_order/repository/custom_order_repository.dart';
import '../../city_area_selector/viewmodel/city_area_viewmodel.dart';

part 'custom_order_viewmodel.g.dart';

class InstallmentPlan {
  final String month;
  final double amount;
  final int srNo;

  InstallmentPlan({
    required this.month,
    required this.amount,
    required this.srNo,
  });
}

class CustomOrderState {
  final String productTitle;
  final double productPrice;
  final double advancePrice;
  final int installmentMonths;
  final List<InstallmentPlan> plans;
  final double totalDealAmount;
  final double sourcingFee;
  final double totalPayable;
  final bool hasDiscount;
  final bool isSubmitting;
  final bool isSuccess;
  final bool isValidatingRefCode;
  final bool isRefCodeValid;
  final bool isLoadingUserDetails; // ← NEW: tracks session prefill loading
  final String? errorMessage;
  final String? refCode;
  final String? fullName;
  final String? phoneNumber;
  final String? address;

  const CustomOrderState({
    this.productTitle = '',
    this.productPrice = 0.0,
    this.advancePrice = 0.0,
    this.installmentMonths = 3,
    this.plans = const [],
    this.totalDealAmount = 0.0,
    this.sourcingFee = 0.0,
    this.totalPayable = 0.0,
    this.hasDiscount = false,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.isValidatingRefCode = false,
    this.isRefCodeValid = false,
    this.isLoadingUserDetails = false,
    this.errorMessage,
    this.refCode,
    this.fullName,
    this.phoneNumber,
    this.address,
  });

  CustomOrderState copyWith({
    String? productTitle,
    double? productPrice,
    double? advancePrice,
    int? installmentMonths,
    List<InstallmentPlan>? plans,
    double? totalDealAmount,
    double? sourcingFee,
    double? totalPayable,
    bool? hasDiscount,
    bool? isSubmitting,
    bool? isSuccess,
    bool? isValidatingRefCode,
    bool? isRefCodeValid,
    bool? isLoadingUserDetails,
    String? errorMessage,
    String? refCode,
    String? fullName,
    String? phoneNumber,
    String? address,
    bool clearError = false,
    bool clearRefCode = false,
  }) {
    return CustomOrderState(
      productTitle: productTitle ?? this.productTitle,
      productPrice: productPrice ?? this.productPrice,
      advancePrice: advancePrice ?? this.advancePrice,
      installmentMonths: installmentMonths ?? this.installmentMonths,
      plans: plans ?? this.plans,
      totalDealAmount: totalDealAmount ?? this.totalDealAmount,
      sourcingFee: sourcingFee ?? this.sourcingFee,
      totalPayable: totalPayable ?? this.totalPayable,
      hasDiscount: hasDiscount ?? this.hasDiscount,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      isValidatingRefCode: isValidatingRefCode ?? this.isValidatingRefCode,
      isRefCodeValid: isRefCodeValid ?? this.isRefCodeValid,
      isLoadingUserDetails: isLoadingUserDetails ?? this.isLoadingUserDetails,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      refCode: clearRefCode ? null : (refCode ?? this.refCode),
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
    );
  }

  bool get hasValidPlan => plans.isNotEmpty && errorMessage == null;

  bool get hasCompletePersonalInfo =>
      fullName != null &&
      fullName!.trim().isNotEmpty &&
      phoneNumber != null &&
      phoneNumber!.trim().isNotEmpty &&
      address != null &&
      address!.trim().isNotEmpty;

  double get minimumAdvance => productPrice * 0.2;

  double get sourcingFeePercent => hasDiscount ? 0.005 : 0.01;

  String get formattedMonthlyPayment =>
      plans.isNotEmpty ? plans.first.amount.toStringAsFixed(0) : '0';
}

@riverpod
class CustomOrderViewModel extends _$CustomOrderViewModel {
  Timer? _refDebounce;

  @override
  CustomOrderState build() {
    ref.onDispose(() => _refDebounce?.cancel());
    return const CustomOrderState();
  }

  // ── Load user details from session (called when entering Phase 3) ─────────
  //
  // Only prefills if the field is currently empty — so edited values are
  // never overwritten on a hot-reload or accidental double-call.
  Future<void> loadUserDetails() async {
    // Skip if already loaded or currently loading
    if (state.isLoadingUserDetails) return;
    if (state.hasCompletePersonalInfo) return;

    state = state.copyWith(isLoadingUserDetails: true);

    final isLoggedIn = await SessionManager.isLoggedIn();
    if (!isLoggedIn) {
      state = state.copyWith(isLoadingUserDetails: false);
      return;
    }

    final name = await SessionManager.getUserName();
    final phone = await SessionManager.getPhone();
    final address = await SessionManager.getAddress();
    final cityIdStr = await SessionManager.getCityId();
    final areaIdStr = await SessionManager.getAreaId();

    state = state.copyWith(
      fullName: state.fullName?.isNotEmpty == true ? state.fullName : name,
      phoneNumber: state.phoneNumber?.isNotEmpty == true
          ? state.phoneNumber
          : phone,
      address: state.address?.isNotEmpty == true ? state.address : address,
      isLoadingUserDetails: false,
    );

    // Auto-select city & area in the shared CityAreaViewModel
    final cityAreaNotifier = ref.read(cityAreaViewModelProvider.notifier);
    final cityAreaState = ref.read(cityAreaViewModelProvider);

    final storedCityId = int.tryParse(cityIdStr ?? '');
    final storedAreaId = int.tryParse(areaIdStr ?? '');

    if (storedCityId != null &&
        cityAreaState.selectedCity == null &&
        cityAreaState.cities.isNotEmpty) {
      final match = cityAreaState.cities.where((c) => c.id == storedCityId);
      if (match.isNotEmpty) {
        await cityAreaNotifier.onCityChanged(match.first);
      }
    }

    // Area needs to be set after onCityChanged fetches areas
    if (storedAreaId != null && cityAreaState.selectedArea == null) {
      // Poll briefly for areas to load after city selection
      for (var i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 150));
        final updated = ref.read(cityAreaViewModelProvider);
        if (updated.areas.isNotEmpty) {
          final match = updated.areas.where((a) => a.id == storedAreaId);
          if (match.isNotEmpty) {
            cityAreaNotifier.onAreaChanged(match.first);
          }
          break;
        }
      }
    }
  }

  /// Call this when returning from EditProfilePage so Phase 3 refreshes
  /// with the latest saved values from SessionManager.
  Future<void> refreshUserDetails() async {
    final name = await SessionManager.getUserName();
    final phone = await SessionManager.getPhone();
    final address = await SessionManager.getAddress();
    final cityIdStr = await SessionManager.getCityId();
    final areaIdStr = await SessionManager.getAreaId();

    state = state.copyWith(
      fullName: name,
      phoneNumber: phone,
      address: address,
    );

    final cityAreaNotifier = ref.read(cityAreaViewModelProvider.notifier);
    final storedCityId = int.tryParse(cityIdStr ?? '');
    final storedAreaId = int.tryParse(areaIdStr ?? '');

    if (storedCityId != null) {
      final cityAreaState = ref.read(cityAreaViewModelProvider);
      final cityMatch = cityAreaState.cities.where((c) => c.id == storedCityId);
      if (cityMatch.isNotEmpty) {
        await cityAreaNotifier.onCityChanged(cityMatch.first);

        // Wait for areas to load then set area
        if (storedAreaId != null) {
          for (var i = 0; i < 10; i++) {
            await Future.delayed(const Duration(milliseconds: 150));
            final updated = ref.read(cityAreaViewModelProvider);
            if (updated.areas.isNotEmpty) {
              final areaMatch = updated.areas.where(
                (a) => a.id == storedAreaId,
              );
              if (areaMatch.isNotEmpty) {
                cityAreaNotifier.onAreaChanged(areaMatch.first);
              }
              break;
            }
          }
        }
      }
    }
  }

  // ── Simple field updates ──────────────────────────────────────────────────

  void updateProductTitle(String v) =>
      state = state.copyWith(productTitle: v, clearError: true);

  void updateFullName(String v) =>
      state = state.copyWith(fullName: v, clearError: true);

  void updatePhone(String v) {
    final cleaned = v.replaceAll(RegExp(r'[^0-9+]'), '');
    state = state.copyWith(phoneNumber: cleaned, clearError: true);
  }

  void updateAddress(String v) =>
      state = state.copyWith(address: v, clearError: true);

  void updateProductPrice(String v) {
    final price = double.tryParse(v.replaceAll(',', '')) ?? 0.0;
    state = state.copyWith(productPrice: price, clearError: true);
  }

  void updateAdvancePrice(String v) {
    final advance = double.tryParse(v.replaceAll(',', '')) ?? 0.0;
    state = state.copyWith(advancePrice: advance, clearError: true);
  }

  void updateMonths(int months) =>
      state = state.copyWith(installmentMonths: months, clearError: true);

  // ── Plan calculation ──────────────────────────────────────────────────────

  void calculatePlan() => _calculate();

  void _calculate() {
    final price = state.productPrice;
    final advance = state.advancePrice;
    final months = state.installmentMonths;

    if (price <= 0) {
      state = state.copyWith(
        plans: [],
        totalPayable: 0,
        totalDealAmount: 0,
        clearError: true,
      );
      return;
    }

    if (price < 10000) {
      state = state.copyWith(
        errorMessage: 'Minimum product price is Rs. 10,000',
        plans: [],
      );
      return;
    }

    final minAdvance = price * 0.2;
    if (advance < minAdvance) {
      state = state.copyWith(
        errorMessage:
            'Minimum advance is 20% (Rs. ${minAdvance.toStringAsFixed(0)})',
        plans: [],
      );
      return;
    }

    if (advance >= price) {
      state = state.copyWith(
        errorMessage: 'Advance cannot be equal to or more than product price',
        plans: [],
      );
      return;
    }

    final principal = price - advance;
    const markupRate = 0.04;
    final totalMarkup = principal * markupRate * months;
    final totalDeal = principal + totalMarkup;
    final dealPriceForApi = price + totalMarkup;
    final sourcingFee = price * state.sourcingFeePercent;
    final monthlyAmount = totalDeal / months;

    final newPlans = List.generate(
      months,
      (i) => InstallmentPlan(
        month: 'Month ${i + 1}',
        amount: monthlyAmount,
        srNo: i + 1,
      ),
    );

    state = state.copyWith(
      totalDealAmount: dealPriceForApi,
      sourcingFee: sourcingFee,
      totalPayable: dealPriceForApi + sourcingFee,
      plans: newPlans,
      clearError: true,
    );
  }

  // ── Reference code ────────────────────────────────────────────────────────

  void updateRefCode(String code) {
    _refDebounce?.cancel();

    if (code.trim().isEmpty) {
      state = state.copyWith(
        hasDiscount: false,
        isRefCodeValid: false,
        clearRefCode: true,
        clearError: true,
      );
      _calculate();
      return;
    }

    state = state.copyWith(isValidatingRefCode: true, clearError: true);

    _refDebounce = Timer(const Duration(milliseconds: 800), () async {
      await _validateAndApplyRefCode(code.trim());
    });
  }

  Future<void> _validateAndApplyRefCode(String code) async {
    try {
      final isValid = await ref
          .read(customOrderRepositoryProvider)
          .validateRefCode(code);

      state = state.copyWith(
        hasDiscount: isValid,
        isRefCodeValid: isValid,
        refCode: isValid ? code : null,
        isValidatingRefCode: false,
        errorMessage: isValid ? null : 'Invalid reference code',
        clearError: isValid,
      );
    } catch (_) {
      state = state.copyWith(
        hasDiscount: false,
        isRefCodeValid: false,
        clearRefCode: true,
        isValidatingRefCode: false,
        errorMessage: 'Could not validate reference code. Try again.',
      );
    }

    _calculate();
  }

  // ── Submission ────────────────────────────────────────────────────────────

  Future<void> submit() async {
    final validationError = _validateSubmission();
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final cityArea = ref.read(cityAreaViewModelProvider);
      final uuid = await SessionManager.getUserUuid();

      final fields = {
        'uuid': uuid,
        'product_title': state.productTitle.trim().isEmpty
            ? 'Custom Product'
            : state.productTitle.trim(),
        'product_price': state.productPrice.toString(),
        'advance_price': state.advancePrice.toString(),
        'supplier_reference_code': state.refCode ?? '',
        'total_deal_price': state.totalDealAmount.toString(),
        'sourcing_fee': state.sourcingFee.toString(),
        'total_payable': state.totalPayable.toString(),
        'tenure_months': state.installmentMonths.toString(),
        'monthly_installment': state.formattedMonthlyPayment,
        'name': state.fullName!.trim(),
        'phone': state.phoneNumber!.trim(),
        'city_id': cityArea.selectedCity!.id.toString(),
        'area_id': cityArea.selectedArea!.id.toString(),
        'address': state.address!.trim(),
      };

      final response = await ref
          .read(customOrderRepositoryProvider)
          .submitOrder(fields);

      if (response != null && response['success'] == true) {
        state = state.copyWith(isSubmitting: false, isSuccess: true);
      } else {
        final msg =
            response?['message'] ??
            response?['error'] ??
            'Failed to submit order. Please try again.';
        state = state.copyWith(isSubmitting: false, errorMessage: msg);
      }
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: _parseError(e));
    }
  }

  // ── Validation ────────────────────────────────────────────────────────────

  String? _validateSubmission() {
    if (state.plans.isEmpty) {
      return 'Please calculate your installment plan first';
    }
    if (state.errorMessage != null) return state.errorMessage;

    if (state.fullName == null || state.fullName!.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (state.fullName!.trim().length < 3) {
      return 'Please enter a valid full name';
    }

    if (state.phoneNumber == null || state.phoneNumber!.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    if (state.phoneNumber!.replaceAll(RegExp(r'[^0-9]'), '').length < 10) {
      return 'Please enter a valid phone number (min 10 digits)';
    }

    final cityArea = ref.read(cityAreaViewModelProvider);
    if (cityArea.selectedCity == null) return 'Please select your city';
    if (cityArea.selectedArea == null) return 'Please select your area';

    if (state.address == null || state.address!.trim().isEmpty) {
      return 'Please enter your residential address';
    }
    if (state.address!.trim().length < 10) {
      return 'Please enter a complete address';
    }

    return null;
  }

  String _parseError(dynamic e) {
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('NetworkException')) {
      return 'No internet connection. Please check your network.';
    }
    if (s.contains('TimeoutException'))
      return 'Request timed out. Please try again.';
    if (s.contains('500') || s.contains('502'))
      return 'Server error. Please try again later.';
    if (s.contains('401') || s.contains('403'))
      return 'Authentication failed. Please log in again.';
    return 'Something went wrong. Please try again.';
  }

  void reset() => state = const CustomOrderState();
  void clearError() => state = state.copyWith(clearError: true);
}
