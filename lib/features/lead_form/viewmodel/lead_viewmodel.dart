import 'dart:io';
import 'package:atompro/features/city_area_selector/viewmodel/city_area_viewmodel.dart';
import 'package:atompro/features/lead_form/repository/lead_form_repo.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'lead_viewmodel.g.dart';

class LeadState {
  final bool isSubmitting;
  final File? productImages; // To store the selected image
  final String? errorMessage;

  LeadState({this.isSubmitting = false, this.productImages, this.errorMessage});

  LeadState copyWith({
    bool? isSubmitting,
    File? productImages,
    String? errorMessage,
  }) {
    return LeadState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      productImages: productImages ?? this.productImages,
      errorMessage: errorMessage,
    );
  }
}

@riverpod
class LeadViewModel extends _$LeadViewModel {
  @override
  LeadState build() => LeadState();

  // Handle Image Selection
  void setImage(File file) {
    state = state.copyWith(productImages: file);
  }

  // Submit Lead logic
  // lead_viewmodel.dart
  Future<bool> submitLead({
    required String fullName,
    required String contactNumber,
    required String productTitle,
  }) async {
    final cityAreaState = ref.read(cityAreaViewModelProvider);

    if (cityAreaState.selectedCity == null ||
        cityAreaState.selectedArea == null) {
      state = state.copyWith(errorMessage: "Please select city and area");
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final repo = ref.read(leadFormRepoProvider);

      // TEXT DATA
      final data = {
        "full_name": fullName,
        "contact_number": contactNumber,
        "city_id": cityAreaState.selectedCity!.id,
        "area_id": cityAreaState.selectedArea!.id,
        "product_title": productTitle,
      };

      // FILE DATA (only if image exists)
      final Map<String, File> files = {};

      if (state.productImages != null) {
        files["product_images[]"] = state.productImages!;
      }

      await repo.submitLead(data, files);

      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }

  void reset() {
    state = LeadState(); // Returns to initial state (null image, false loading)
  }
}
