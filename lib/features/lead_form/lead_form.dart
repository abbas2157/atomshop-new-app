import 'dart:io';
import 'package:atompro/core/common/widgets/custom_button.dart';
import 'package:atompro/core/common/widgets/custom_text_field.dart';
import 'package:atompro/core/style/app_text_styles.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:atompro/core/style/extensions.dart';
import 'package:atompro/features/city_area_selector/view/city_area_selector_view.dart';
import 'package:atompro/features/city_area_selector/viewmodel/city_area_viewmodel.dart';
import 'package:atompro/features/lead_form/viewmodel/lead_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:image_picker/image_picker.dart';

class LeadForm extends ConsumerStatefulWidget {
  const LeadForm({super.key});

  @override
  ConsumerState<LeadForm> createState() => _LeadFormState();
}

class _LeadFormState extends ConsumerState<LeadForm> {
  // 1. Controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _productCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _productCtrl.dispose();
    super.dispose();
  }

  // 2. Image Picker Logic
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      ref.read(leadViewModelProvider.notifier).setImage(File(pickedFile.path));
    }
  }

  // 3. Success Dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorPalette.accentRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                color: ColorPalette.accentRed,
                size: 60,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              "Submission Successful",
              style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.h),
            Text(
              "Our team will contact you shortly to process your order.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            SizedBox(height: 24.h),
            CustomButton(
              title: "Done",
              onPressed: () => Navigator.pop(context),
              backgroundColor: ColorPalette.accentRed,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leadState = ref.watch(leadViewModelProvider);
    final leadVm = ref.read(leadViewModelProvider.notifier);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Container(
        decoration: BoxDecoration(
          color: ColorPalette.accentRed,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12.r),
            topRight: Radius.circular(12.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          top: context.h(10),
          left: context.h(1),
          right: context.h(1),
          bottom: context.h(1),
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12.r),
              topRight: Radius.circular(12.r),
            ),
          ),
          padding: EdgeInsets.all(context.h(10)),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: context.h(5)),
                Text(
                  "Connect with our Team",
                  style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w700),
                ).alignTopLeft,
                SizedBox(height: context.h(5)),
                const Text(
                  "Please fill out the form below to proceed with your purchase.",
                ),

                SizedBox(height: context.h(15)),

                // Input Fields
                CustomTextField(
                  controller: _nameCtrl,
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: ColorPalette.secondary,
                    size: 20,
                  ),
                ),

                SizedBox(height: context.h(10)),
                CustomTextField(
                  controller: _phoneCtrl,
                  labelText: 'Contact Number',
                  hintText: '03001481947',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icon(
                    Icons.call_outlined,
                    color: ColorPalette.secondary,
                    size: 20,
                  ),
                ),

                SizedBox(height: context.h(10)),
                const CityAreaWidget(), // Handled by CityAreaViewModel internally

                SizedBox(height: context.h(10)),
                CustomTextField(
                  controller: _productCtrl,
                  labelText: 'Product',
                  hintText: 'eg, iphone 16 pro max',
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icon(
                    Icons.shopping_bag_outlined,
                    color: ColorPalette.secondary,
                    size: 20,
                  ),
                ),

                SizedBox(height: context.h(20)),

                // Image Selector Container
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: ColorPalette.surfaceGray,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: ColorPalette.border, width: 1),
                    ),
                    child: leadState.productImages != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                leadState.productImages!,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => leadVm.setImage(
                                    null as dynamic,
                                  ), // Reset image
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.black54,
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                color: ColorPalette.secondary,
                                size: 40,
                              ),
                              SizedBox(height: context.h(5)),
                              Text(
                                "Select Product Image (Optional)",
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                  ),
                ),

                if (leadState.errorMessage != null) ...[
                  SizedBox(height: 10.h),
                  Text(
                    leadState.errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 12.sp),
                  ),
                ],

                SizedBox(height: context.h(20)),

                // Submit Button
                CustomButton(
                  title: leadState.isSubmitting ? "Submitting..." : "Submit",
                  isLoading: leadState.isSubmitting,
                  onPressed: leadState.isSubmitting
                      ? null
                      : () async {
                          final success = await leadVm.submitLead(
                            fullName: _nameCtrl.text,
                            contactNumber: _phoneCtrl.text,
                            productTitle: _productCtrl.text,
                          );

                          if (success && mounted) {
                            // 1. Clear Text Controllers
                            _nameCtrl.clear();
                            _phoneCtrl.clear();
                            _productCtrl.clear();

                            // 2. Clear Image (LeadState)
                            ref.read(leadViewModelProvider.notifier).reset();

                            // 3. Clear City/Area (CityAreaState)
                            ref
                                .read(cityAreaViewModelProvider.notifier)
                                .reset();

                            // 4. Show Success UI
                            _showSuccessDialog();
                          }
                        },
                  backgroundColor: ColorPalette.accentRed,
                ),
                SizedBox(height: context.h(10)),
              ],
            ),
          ),
        ),
      ).paddingHorizontal(16),
    );
  }
}
