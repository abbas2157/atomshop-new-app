import 'dart:io';

import 'package:atompro/core/auth/session_manager.dart';
import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/routes/app_route_constants.dart';
import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/customer/city_area_selector/model/area_model.dart';
import 'package:atompro/features/customer/city_area_selector/model/city_model.dart';
import 'package:atompro/features/customer/profile/view/repo/profile_repo.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_viewmodel.g.dart';

// ── State ──────────────────────────────────────────────────────────────────
class ProfileEditState {
  final String? uuid;
  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final String? cityId;
  final String? areaId;
  final String? profilePictureUrl;
  final bool isLoading;
  final bool isSaving;
  final bool isUploadingPicture;

  const ProfileEditState({
    this.uuid,
    this.name,
    this.email,
    this.phone,
    this.address,
    this.cityId,
    this.areaId,
    this.profilePictureUrl,
    this.isLoading = false,
    this.isSaving = false,
    this.isUploadingPicture = false,
  });

  ProfileEditState copyWith({
    String? uuid,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? cityId,
    String? areaId,
    String? profilePictureUrl,
    bool? isLoading,
    bool? isSaving,
    bool? isUploadingPicture,
    bool clearPictureUrl = false,
  }) => ProfileEditState(
    uuid: uuid ?? this.uuid,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    cityId: cityId ?? this.cityId,
    areaId: areaId ?? this.areaId,
    profilePictureUrl: clearPictureUrl ? null : (profilePictureUrl ?? this.profilePictureUrl),
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    isUploadingPicture: isUploadingPicture ?? this.isUploadingPicture,
  );

  bool get isProfileComplete =>
      phone != null &&
      phone!.trim().isNotEmpty &&
      address != null &&
      address!.trim().isNotEmpty &&
      cityId != null &&
      cityId!.trim().isNotEmpty &&
      cityId != 'null' &&
      areaId != null &&
      areaId!.trim().isNotEmpty &&
      areaId != 'null';
}

// ── ViewModel ─────────────────────────────────────────────────────────────
@riverpod
class ProfileViewModel extends _$ProfileViewModel {
  @override
  ProfileEditState build() {
    Future.microtask(() => loadFromSession());
    return const ProfileEditState(isLoading: true);
  }

  /// Pull current values from secure storage so fields are pre-filled.
  Future<void> loadFromSession() async {
    state = state.copyWith(isLoading: true);
    final uuid = await SessionManager.getUserUuid();
    final name = await SessionManager.getUserName();
    final email = await SessionManager.getEmail();
    final phone = await SessionManager.getPhone();
    final address = await SessionManager.getAddress();
    final cityId = await SessionManager.getCityId();
    final areaId = await SessionManager.getAreaId();

    state = state.copyWith(
      uuid: uuid,
      name: name,
      email: email,
      phone: phone,
      address: address,
      cityId: cityId,
      areaId: areaId,
      isLoading: false,
    );

    // Load picture in the background — non-blocking
    if (uuid != null) {
      final url = await ref.read(profileRepositoryProvider).getProfilePicture(uuid);
      if (url != null) state = state.copyWith(profilePictureUrl: url);
    }
  }

  Future<void> uploadPicture(File imageFile) async {
    final uuid = state.uuid;
    if (uuid == null) return;
    state = state.copyWith(isUploadingPicture: true);
    try {
      final url = await ref
          .read(profileRepositoryProvider)
          .uploadProfilePicture(userUuid: uuid, imageFile: imageFile);
      state = state.copyWith(profilePictureUrl: url, isUploadingPicture: false);
      SnackbarService().showSuccessSnackBar('Profile picture updated.');
    } catch (e) {
      state = state.copyWith(isUploadingPicture: false);
      SnackbarService().showErrorSnackBar('Failed to upload picture.');
    }
  }

  Future<void> saveProfile({
    required String name,
    required String phone,
    required String email,
    required String address,

    required CityModel? selectedCity,
    required AreaModel? selectedArea,
    required bool isCompletionFlow,
  }) async {
    // ── Validation ─────────────────────────────────────────────────────────
    if (name.trim().isEmpty) {
      SnackbarService().showErrorSnackBar('Please enter your name.');
      return;
    }
    if (phone.trim().isEmpty) {
      SnackbarService().showErrorSnackBar('Please enter your phone number.');
      return;
    }
    if (email.trim().isEmpty) {
      SnackbarService().showErrorSnackBar('Please enter your email.');
      return;
    }
    if (address.trim().isEmpty) {
      SnackbarService().showErrorSnackBar('Please enter your address.');
      return;
    }
    if (selectedCity == null) {
      SnackbarService().showErrorSnackBar('Please select your city.');
      return;
    }
    if (selectedArea == null) {
      SnackbarService().showErrorSnackBar('Please select your area.');
      return;
    }

    state = state.copyWith(isSaving: true);
    try {
      final uuid = state.uuid;
      if (uuid == null) throw Exception('User session not found.');

      final response = await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            userUuid: uuid,
            name: name.trim(),
            phone: phone.trim(),
            email: email.trim(),
            address: address.trim(),
            cityId: selectedCity.id,
            areaId: selectedArea.id,
          );

      if (response['success'] == true) {
        // ── Persist updated values locally ──────────────────────────────
        await SessionManager.saveUserSession(
          token: (await SessionManager.getToken()) ?? '',
          userId: (await SessionManager.getUserId()) ?? '',
          username: name.trim(),
          userUuid: uuid,
          phone: phone.trim(),
          email: email.trim(),
          cityId: selectedCity.id.toString(),
          areaId: selectedArea.id.toString(),
          address: address.trim(),
        );

        state = state.copyWith(isSaving: false);
        SnackbarService().showSuccessSnackBar('Profile updated successfully!');

        if (isCompletionFlow) {
          AppNavigator.clearStackAndPush(AppRoutes.homePage);
        } else {
          AppNavigator.getBack();
        }
      } else {
        final msg = response['message'] ?? 'Failed to update profile.';
        state = state.copyWith(isSaving: false);
        SnackbarService().showErrorSnackBar(msg.toString());
      }
    } catch (e) {
      state = state.copyWith(isSaving: false);
      SnackbarService().showErrorSnackBar(
        'Something went wrong. Please try again.',
      );
    }
  }
}

// ── Helper — called from AuthViewModel after login ─────────────────────────

/// Returns true when the login response (or local session) is missing
/// any required profile field: phone, address, city_id, area_id.
bool isProfileIncomplete(Map<String, dynamic> userData) {
  final phone = userData['phone'];
  final address = userData['address'];
  final cityId = userData['city_id'];
  final areaId = userData['area_id'];

  bool blank(dynamic v) =>
      v == null || v.toString().trim().isEmpty || v.toString() == 'null';

  return blank(phone) || blank(address) || blank(cityId) || blank(areaId);
}
