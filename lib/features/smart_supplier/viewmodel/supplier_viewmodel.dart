import 'dart:io';
import 'package:atompro/features/city_area_selector/viewmodel/city_area_viewmodel.dart';
import 'package:atompro/features/smart_supplier/repo/supplier_repo.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'supplier_viewmodel.g.dart';

// ── Category model ─────────────────────────────────────────────────────────

class CategoryModel {
  final int id;
  final String title;

  const CategoryModel({required this.id, required this.title});

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      CategoryModel(id: json['id'] as int, title: json['title'] as String);
}

// ── Image limit: 10 MB — passes virtually any phone photo without friction ──
const int _maxImageBytes = 10 * 1024 * 1024;
const String _maxImageLabel = '10 MB';

// ── State ──────────────────────────────────────────────────────────────────

class SupplierState {
  // Step 1
  final String name;
  final String businessName;
  final String phone;
  final String email;
  final String password;

  // Step 2
  final String cnicNic;
  final String businessType;
  final int? categoryId;
  final String businessRegistrationNumber;

  // Step 3 — city/area lives in CityAreaViewModel
  final String address;

  // Step 4 — files
  final File? locationPhoto;
  final File? cnicFront;
  final File? cnicBack;

  // Loaded data
  final List<CategoryModel> categories;
  final bool isCategoriesLoading;

  // UI
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final String? successMessage;

  const SupplierState({
    this.name = '',
    this.businessName = '',
    this.phone = '',
    this.email = '',
    this.password = '',
    this.cnicNic = '',
    this.businessType = '',
    this.categoryId,
    this.businessRegistrationNumber = '',
    this.address = '',
    this.locationPhoto,
    this.cnicFront,
    this.cnicBack,
    this.categories = const [],
    this.isCategoriesLoading = false,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.successMessage,
  });

  bool get hasAllImages =>
      locationPhoto != null && cnicFront != null && cnicBack != null;

  SupplierState copyWith({
    String? name,
    String? businessName,
    String? phone,
    String? email,
    String? password,
    String? cnicNic,
    String? businessType,
    int? categoryId,
    String? businessRegistrationNumber,
    String? address,
    File? locationPhoto,
    File? cnicFront,
    File? cnicBack,
    List<CategoryModel>? categories,
    bool? isCategoriesLoading,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
  }) {
    return SupplierState(
      name: name ?? this.name,
      businessName: businessName ?? this.businessName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      cnicNic: cnicNic ?? this.cnicNic,
      businessType: businessType ?? this.businessType,
      categoryId: categoryId ?? this.categoryId,
      businessRegistrationNumber:
          businessRegistrationNumber ?? this.businessRegistrationNumber,
      address: address ?? this.address,
      locationPhoto: locationPhoto ?? this.locationPhoto,
      cnicFront: cnicFront ?? this.cnicFront,
      cnicBack: cnicBack ?? this.cnicBack,
      categories: categories ?? this.categories,
      isCategoriesLoading: isCategoriesLoading ?? this.isCategoriesLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

// ── Viewmodel ──────────────────────────────────────────────────────────────

@riverpod
class SupplierViewmodel extends _$SupplierViewmodel {
  @override
  SupplierState build() {
    Future.microtask(loadCategories);
    return const SupplierState();
  }

  // ── Categories ────────────────────────────────────────────────────────────

  Future<void> loadCategories() async {
    state = state.copyWith(isCategoriesLoading: true, clearError: true);
    try {
      final response = await ref.read(supplierRepoProvider).getCategories();
      if (response['success'] == true) {
        final list = (response['data'] as List<dynamic>)
            .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(categories: list, isCategoriesLoading: false);
      } else {
        state = state.copyWith(
          isCategoriesLoading: false,
          errorMessage: 'Failed to load categories.',
        );
      }
    } catch (_) {
      state = state.copyWith(
        isCategoriesLoading: false,
        errorMessage: 'Failed to load categories. Please restart.',
      );
    }
  }

  // ── Field updates ─────────────────────────────────────────────────────────

  void updateName(String v) =>
      state = state.copyWith(name: v, clearError: true);
  void updateBusinessName(String v) =>
      state = state.copyWith(businessName: v, clearError: true);
  void updatePhone(String v) =>
      state = state.copyWith(phone: v, clearError: true);
  void updateEmail(String v) =>
      state = state.copyWith(email: v, clearError: true);
  void updatePassword(String v) =>
      state = state.copyWith(password: v, clearError: true);
  void updateCnic(String v) =>
      state = state.copyWith(cnicNic: v, clearError: true);
  void updateBusinessType(String? v) =>
      state = state.copyWith(businessType: v ?? '', clearError: true);
  void updateCategory(int? id) =>
      state = state.copyWith(categoryId: id, clearError: true);
  void updateRegNumber(String v) =>
      state = state.copyWith(businessRegistrationNumber: v, clearError: true);
  void updateAddress(String v) =>
      state = state.copyWith(address: v, clearError: true);

  void clearError() => state = state.copyWith(clearError: true);

  // ── Image picking with size guard ─────────────────────────────────────────

  String? _checkSize(File file, String label) {
    final bytes = file.lengthSync();
    if (bytes > _maxImageBytes) {
      final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
      return '$label is $mb MB. Max allowed size is $_maxImageLabel.';
    }
    return null;
  }

  /// Returns null on success, or an error string for the view to show.
  String? setLocationPhoto(File file) {
    final err = _checkSize(file, 'Location photo');
    if (err != null) return err;
    state = state.copyWith(locationPhoto: file, clearError: true);
    return null;
  }

  String? setCnicFront(File file) {
    final err = _checkSize(file, 'CNIC front');
    if (err != null) return err;
    state = state.copyWith(cnicFront: file, clearError: true);
    return null;
  }

  String? setCnicBack(File file) {
    final err = _checkSize(file, 'CNIC back');
    if (err != null) return err;
    state = state.copyWith(cnicBack: file, clearError: true);
    return null;
  }

  // ── Per-step validation ───────────────────────────────────────────────────

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
        if (state.cnicNic.trim().isEmpty) {
          return 'CNIC / NIC number is required';
        }
        if (state.businessType.isEmpty) return 'Please select a business type';
        if (state.categoryId == null) return 'Please select a product category';
        return null;

      case 2:
        final cityArea = ref.read(cityAreaViewModelProvider);
        if (cityArea.selectedCity == null) return 'Please select your city';
        if (cityArea.selectedArea == null) return 'Please select your area';
        if (state.address.trim().isEmpty) return 'Complete address is required';
        return null;

      case 3:
        if (state.locationPhoto == null) {
          return 'Business location photo is required';
        }
        if (state.cnicFront == null) return 'CNIC front image is required';
        if (state.cnicBack == null) return 'CNIC back image is required';
        return null;

      default:
        return null;
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> submit() async {
    final cityArea = ref.read(cityAreaViewModelProvider);

    if (cityArea.selectedCity == null || cityArea.selectedArea == null) {
      state = state.copyWith(errorMessage: 'Please select city and area');
      return;
    }
    if (!state.hasAllImages) {
      state = state.copyWith(
        errorMessage: 'Please upload all required documents',
      );
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final fields = <String, dynamic>{
        'name': state.name.trim(),
        'business_name': state.businessName.trim(),
        'phone': state.phone.trim(),
        'email': state.email.trim(),
        'password': state.password,
        'cnic_nic': state.cnicNic.trim(),
        'business_type': state.businessType,
        'category_id': state.categoryId,
        'business_registration_number': state.businessRegistrationNumber.trim(),
        'address': state.address.trim(),
        'city_id': cityArea.selectedCity!.id,
        'area_id': cityArea.selectedArea!.id,
      };

      final response = await ref
          .read(supplierRepoProvider)
          .submit(
            fields: fields,
            locationPhoto: state.locationPhoto!,
            cnicFront: state.cnicFront!,
            cnicBack: state.cnicBack!,
          );

      if (response['success'] == true) {
        state = state.copyWith(
          isSubmitting: false,
          isSuccess: true,
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

  void reset() => state = const SupplierState();
}
