import 'dart:io';
import 'package:atompro/features/customer/city_area_selector/viewmodel/city_area_viewmodel.dart';
import 'package:atompro/features/customer/lead_form/repository/lead_form_repo.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lead_viewmodel.g.dart';

class LeadState {
  final bool isSubmitting;
  final File? productImages;
  final String? errorMessage;
  final bool isWhatsapp;

  LeadState({
    this.isSubmitting = false,
    this.productImages,
    this.errorMessage,
    this.isWhatsapp = false,
  });

  LeadState copyWith({
    bool? isSubmitting,
    File? productImages,
    String? errorMessage,
    bool? isWhatsapp,
  }) {
    return LeadState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      productImages: productImages,
      errorMessage: errorMessage,
      isWhatsapp: isWhatsapp ?? this.isWhatsapp,
    );
  }
}

@riverpod
class LeadViewModel extends _$LeadViewModel {
  @override
  LeadState build() => LeadState();

  // ✅ Set Image
  void setImage(File? file) {
    state = state.copyWith(productImages: file);
  }

  // ✅ Clear Image
  void clearImage() {
    state = state.copyWith(productImages: null);
  }

  // ✅ Toggle WhatsApp
  void toggleWhatsapp(bool value) {
    state = state.copyWith(isWhatsapp: value);
  }

  // ✅ Submit Lead
  Future<bool> submitLead({
    required String fullName,
    required String contactNumber,
    required String productTitle,
  }) async {
    final cityAreaState = ref.read(cityAreaViewModelProvider);

    fullName = fullName.trim();
    contactNumber = contactNumber.trim();
    productTitle = productTitle.trim();

    List<String> errors = [];

    if (fullName.isEmpty) {
      errors.add("Please enter your full name");
    }

    if (contactNumber.isEmpty) {
      errors.add("Please enter your contact number");
    } else if (contactNumber.length < 11) {
      errors.add("Please enter a valid phone number");
    }

    if (productTitle.isEmpty) {
      errors.add("Please enter product title");
    }

    if (cityAreaState.selectedCity == null) {
      errors.add("Please select a city");
    }

    if (cityAreaState.selectedArea == null) {
      errors.add("Please select an area");
    }

    if (errors.isNotEmpty) {
      state = state.copyWith(errorMessage: errors.join("\n"));
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final repo = ref.read(leadFormRepoProvider);

      final data = {
        "full_name": fullName,
        "contact_number": contactNumber,
        "city_id": cityAreaState.selectedCity!.id,
        "area_id": cityAreaState.selectedArea!.id,
        "product_title": productTitle,
        "available_on_whatsapp": state.isWhatsapp ? 1 : 0,
      };

      final Map<String, File> files = {};

      if (state.productImages != null) {
        files["product_images[]"] = state.productImages!;
      }

      await repo.submitLead(data, files);

      state = LeadState(); // reset state
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: "Something went wrong. Please try again.",
      );
      return false;
    }
  }

  void reset() {
    state = LeadState();
  }
}
