import 'dart:io';
import 'package:atompro/core/common/widgets/custom_button.dart';
import 'package:atompro/core/common/widgets/custom_text_field.dart';
import 'package:atompro/core/style/app_text_styles.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:atompro/features/city_area_selector/view/city_area_selector_view.dart';
import 'package:atompro/features/smart_supplier/viewmodel/supplier_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:image_picker/image_picker.dart';

enum _ImageSlot { location, cnicFront, cnicBack }

class SupplierForm extends ConsumerStatefulWidget {
  const SupplierForm({super.key});

  @override
  ConsumerState<SupplierForm> createState() => _SupplierFormState();
}

class _SupplierFormState extends ConsumerState<SupplierForm>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  final _pageCtrl = PageController();
  late final AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  final _picker = ImagePicker();

  // ── Controllers ───────────────────────────────────────────────────────────

  // Step 1
  final _nameCtrl = TextEditingController();
  final _bizNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // Step 2
  final _cnicCtrl = TextEditingController();
  final _regNumCtrl = TextEditingController();
  String? _bizType;
  String? _selectedCategoryTitle; // local display state for dropdown

  final _bizTypes = const [
    'Individual',
    'Retailer',
    'Wholesaler',
    'Manufacturer',
    'Partnership',
    'Other',
  ];

  // Step 3
  final _addressCtrl = TextEditingController();

  static const _total = 4;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progressAnim = Tween<double>(
      begin: 1 / _total,
      end: 1 / _total,
    ).animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut));
    _progressCtrl.forward();

    // Wire controllers once — survives all rebuilds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = ref.read(supplierViewmodelProvider.notifier);
      _nameCtrl.addListener(() => vm.updateName(_nameCtrl.text));
      _bizNameCtrl.addListener(() => vm.updateBusinessName(_bizNameCtrl.text));
      _phoneCtrl.addListener(() => vm.updatePhone(_phoneCtrl.text));
      _emailCtrl.addListener(() => vm.updateEmail(_emailCtrl.text));
      _passCtrl.addListener(() => vm.updatePassword(_passCtrl.text));
      _cnicCtrl.addListener(() => vm.updateCnic(_cnicCtrl.text));
      _regNumCtrl.addListener(() => vm.updateRegNumber(_regNumCtrl.text));
      _addressCtrl.addListener(() => vm.updateAddress(_addressCtrl.text));
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _progressCtrl.dispose();
    _nameCtrl.dispose();
    _bizNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _cnicCtrl.dispose();
    _regNumCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _goTo(int step) {
    final target = (step + 1) / _total;
    _progressAnim = Tween<double>(
      begin: _progressAnim.value,
      end: target,
    ).animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut));
    _progressCtrl.forward(from: 0);
    setState(() => _step = step);
    _pageCtrl.animateToPage(
      step,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    );
  }

  void _next() {
    final error = ref
        .read(supplierViewmodelProvider.notifier)
        .validateStep(_step);
    if (error != null) {
      _showErrorSnack(error);
      return;
    }
    if (_step < _total - 1) _goTo(_step + 1);
  }

  void _prev() {
    if (_step > 0) _goTo(_step - 1);
  }

  // ── Image picking ─────────────────────────────────────────────────────────

  Future<void> _pickImage(_ImageSlot slot) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85, // light compression — keeps quality, trims size
    );
    if (picked == null || !mounted) return;

    final file = File(picked.path);
    final vm = ref.read(supplierViewmodelProvider.notifier);

    final error = switch (slot) {
      _ImageSlot.location => vm.setLocationPhoto(file),
      _ImageSlot.cnicFront => vm.setCnicFront(file),
      _ImageSlot.cnicBack => vm.setCnicBack(file),
    };

    if (error != null && mounted) _showErrorSnack(error);
  }

  // ── Submission ────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final vm = ref.read(supplierViewmodelProvider.notifier);
    final error = vm.validateStep(_step);
    if (error != null) {
      _showErrorSnack(error);
      return;
    }

    await vm.submit();

    if (!mounted) return;
    final state = ref.read(supplierViewmodelProvider);
    if (state.isSuccess) {
      _showSuccessDialog(
        message: state.successMessage ?? 'Your registration is under review.',
      );
    } else if (state.errorMessage != null) {
      _showErrorSnack(state.errorMessage!);
    }
  }

  // ── Snack / dialog ────────────────────────────────────────────────────────

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: ColorPalette.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessDialog({required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(28.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72.w,
                height: 72.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorPalette.accentGreen.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: ColorPalette.accentGreen,
                  size: 40.sp,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Application Submitted!',
                style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h),
              Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: ColorPalette.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              CustomButton(
                title: 'Done',
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                backgroundColor: ColorPalette.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: ColorPalette.backgroundGray,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [_step1(), _step2(), _step3(), _step4()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final labels = ['Personal', 'Business', 'Location', 'Documents'];
    final icons = [
      Icons.person_outline_rounded,
      Icons.business_center_outlined,
      Icons.location_on_outlined,
      Icons.upload_file_outlined,
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A3277),
            ColorPalette.secondary,
            ColorPalette.secondaryLight,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
              child: Row(
                children: [
                  _navIconBtn(
                    Icons.arrow_back_ios_new_rounded,
                    () => Navigator.pop(context),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Supplier Registration',
                    style: AppTextStyles.h6.copyWith(
                      color: ColorPalette.textWhite,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(100.r),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      '${_step + 1} / $_total',
                      style: AppTextStyles.overline.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Become a Supplier —\nSell on AtomShop',
                    style: AppTextStyles.h4.copyWith(
                      color: ColorPalette.textWhite,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'اپنی مصنوعات ہمارے پلیٹ فارم پر فروخت کریں',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.5),
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: AnimatedBuilder(
                animation: _progressAnim,
                builder: (_, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: _progressAnim.value,
                    minHeight: 3.h,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      ColorPalette.accentGreen,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 14.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Row(
                children: List.generate(_total, (i) {
                  final done = i < _step;
                  final active = i == _step;
                  return Expanded(
                    child: GestureDetector(
                      onTap: done ? () => _goTo(i) : null,
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            width: active ? 34.w : 28.w,
                            height: active ? 34.w : 28.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: done
                                  ? ColorPalette.accentGreen
                                  : active
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.12),
                              border: Border.all(
                                color: done
                                    ? ColorPalette.accentGreen
                                    : active
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.25),
                                width: 1.5,
                              ),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.3),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Icon(
                              done ? Icons.check_rounded : icons[i],
                              size: active ? 15.sp : 12.sp,
                              color: done
                                  ? Colors.white
                                  : active
                                  ? ColorPalette.secondary
                                  : Colors.white.withOpacity(0.4),
                            ),
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            labels[i],
                            style: AppTextStyles.overline.copyWith(
                              color: active
                                  ? Colors.white
                                  : done
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.white.withOpacity(0.35),
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: 14.h),
          ],
        ),
      ),
    );
  }

  Widget _navIconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36.w,
      height: 36.w,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(icon, color: Colors.white, size: 16.sp),
    ),
  );

  // ── Shell ─────────────────────────────────────────────────────────────────

  Widget _shell({
    required String title,
    required String subtitle,
    required List<Widget> fields,
    required Widget actions,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 28.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: ColorPalette.surface,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: ColorPalette.secondary.withOpacity(0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 3.h),
                Text(subtitle, style: AppTextStyles.bodySmall),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  child: const Divider(height: 1, color: ColorPalette.border),
                ),
                ...fields,
              ],
            ),
          ),
          SizedBox(height: 14.h),
          actions,
        ],
      ),
    );
  }

  // ── Step 1 — Personal & Business Info ─────────────────────────────────────

  Widget _step1() => _shell(
    title: 'Personal & Business Info',
    subtitle: 'Tell us about yourself and your business',
    fields: [
      CustomTextField(
        controller: _nameCtrl,
        labelText: 'Full Name',
        hintText: 'eg. Muhammad Ahmed',
        textInputAction: TextInputAction.next,
        prefixIcon: Icon(
          Icons.person_outline_rounded,
          color: ColorPalette.secondary,
          size: 20,
        ),
      ),
      SizedBox(height: 14.h),
      CustomTextField(
        controller: _bizNameCtrl,
        labelText: 'Business Name',
        hintText: 'eg. Ahmed Electronics',
        textInputAction: TextInputAction.next,
        prefixIcon: Icon(
          Icons.storefront_outlined,
          color: ColorPalette.secondary,
          size: 20,
        ),
      ),
      SizedBox(height: 14.h),
      CustomTextField(
        controller: _phoneCtrl,
        labelText: 'Phone Number',
        hintText: '03xxxxxxxxx',
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        prefixIcon: Icon(
          Icons.phone_outlined,
          color: ColorPalette.secondary,
          size: 20,
        ),
      ),
      SizedBox(height: 14.h),
      CustomTextField(
        controller: _emailCtrl,
        labelText: 'Email Address',
        hintText: 'eg. ahmed@example.com',
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        prefixIcon: Icon(
          Icons.email_outlined,
          color: ColorPalette.secondary,
          size: 20,
        ),
      ),
      SizedBox(height: 14.h),
      CustomTextField(
        controller: _passCtrl,
        labelText: 'Password',
        hintText: 'Min. 8 characters',
        isPassword: true,
        textInputAction: TextInputAction.done,
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          color: ColorPalette.secondary,
          size: 20,
        ),
      ),
    ],
    actions: CustomButton(
      title: 'Continue',
      onPressed: _next,
      suffixIcon: Icons.arrow_forward_rounded,
      backgroundColor: ColorPalette.secondary,
    ),
  );

  // ── Step 2 — Business Details ──────────────────────────────────────────────

  Widget _step2() {
    final categories = ref.watch(
      supplierViewmodelProvider.select((s) => s.categories),
    );
    final isCatLoading = ref.watch(
      supplierViewmodelProvider.select((s) => s.isCategoriesLoading),
    );

    return _shell(
      title: 'Business Details',
      subtitle: 'Help us understand your business better',
      fields: [
        CustomTextField(
          controller: _cnicCtrl,
          labelText: 'CNIC / NIC Number',
          hintText: '3520212345678',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          prefixIcon: Icon(
            Icons.credit_card_outlined,
            color: ColorPalette.secondary,
            size: 20,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'For identity verification',
          style: AppTextStyles.caption.copyWith(
            color: ColorPalette.textSecondary,
          ),
        ),
        SizedBox(height: 16.h),

        _fieldLabel('Business Type', required: true),
        SizedBox(height: 8.h),
        _styledDropdown(
          hint: 'Select business type',
          icon: Icons.business_center_outlined,
          value: _bizType,
          items: _bizTypes,
          onChanged: (v) {
            setState(() => _bizType = v);
            ref.read(supplierViewmodelProvider.notifier).updateBusinessType(v);
          },
        ),
        SizedBox(height: 16.h),

        _fieldLabel('Product Category', required: true),
        SizedBox(height: 8.h),
        isCatLoading
            ? _categoryLoadingPlaceholder()
            : _styledDropdown(
                hint: 'Select product category',
                icon: Icons.category_outlined,
                value: _selectedCategoryTitle,
                items: categories.map((c) => c.title).toList(),
                onChanged: (title) {
                  if (title == null) return;
                  final cat = categories.firstWhere((c) => c.title == title);
                  setState(() => _selectedCategoryTitle = title);
                  ref
                      .read(supplierViewmodelProvider.notifier)
                      .updateCategory(cat.id);
                },
              ),
        SizedBox(height: 16.h),

        CustomTextField(
          controller: _regNumCtrl,
          labelText: 'Business Registration Number',
          hintText: 'If applicable',
          textInputAction: TextInputAction.done,
          prefixIcon: Icon(
            Icons.numbers_rounded,
            color: ColorPalette.secondary,
            size: 20,
          ),
        ),
      ],
      actions: _navActions(),
    );
  }

  Widget _categoryLoadingPlaceholder() => Container(
    height: 52.h,
    decoration: BoxDecoration(
      color: ColorPalette.surfaceGray,
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(color: ColorPalette.border),
    ),
    child: Center(
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(ColorPalette.secondary),
        ),
      ),
    ),
  );

  // ── Step 3 — Location ──────────────────────────────────────────────────────

  Widget _step3() => _shell(
    title: 'Location Selection',
    subtitle: 'Set your city and area for service coverage',
    fields: [
      const CityAreaWidget(),
      SizedBox(height: 16.h),
      CustomTextField(
        controller: _addressCtrl,
        labelText: 'Complete Address',
        hintText: 'Street no, Building, Landmark...',
        maxLines: 3,
        textInputAction: TextInputAction.done,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(bottom: 38),
          child: Icon(
            Icons.edit_location_alt_outlined,
            color: ColorPalette.secondary,
            size: 20,
          ),
        ),
      ),
    ],
    actions: _navActions(),
  );

  // ── Step 4 — Documents ────────────────────────────────────────────────────

  Widget _step4() {
    final state = ref.watch(supplierViewmodelProvider);

    return _shell(
      title: 'Document Upload',
      subtitle: 'Required for KYC verification by AtomShop Team',
      fields: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: ColorPalette.backgroundBlueLight,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: ColorPalette.secondaryLight.withOpacity(0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: ColorPalette.secondaryLight,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Upload clear photos (max 10 MB each). Reviewed within 24–48 hours.',
                  style: AppTextStyles.caption.copyWith(
                    color: ColorPalette.secondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),

        _fieldLabel('Business Location Photo', required: true),
        SizedBox(height: 8.h),
        _uploadTile(
          label: 'Shop / Office photo',
          file: state.locationPhoto,
          icon: Icons.add_a_photo_outlined,
          onTap: () => _pickImage(_ImageSlot.location),
        ),
        SizedBox(height: 16.h),

        _fieldLabel('CNIC Images', required: true),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _uploadTile(
                label: 'CNIC Front',
                file: state.cnicFront,
                icon: Icons.credit_card_outlined,
                onTap: () => _pickImage(_ImageSlot.cnicFront),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _uploadTile(
                label: 'CNIC Back',
                file: state.cnicBack,
                icon: Icons.credit_card_outlined,
                onTap: () => _pickImage(_ImageSlot.cnicBack),
              ),
            ),
          ],
        ),
      ],
      actions: Column(
        children: [
          CustomButton(
            title: state.isSubmitting ? 'Submitting...' : 'Submit Application',
            onPressed: state.isSubmitting ? null : _submit,
            suffixIcon: Icons.send_rounded,
            backgroundColor: ColorPalette.secondary,
          ),
          SizedBox(height: 10.h),
          _prevButton(),
        ],
      ),
    );
  }

  // ── Upload tile ───────────────────────────────────────────────────────────

  Widget _uploadTile({
    required String label,
    required File? file,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final uploaded = file != null;
    final fileName = uploaded ? file.path.split('/').last : null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 10.w),
        decoration: BoxDecoration(
          color: uploaded
              ? ColorPalette.accentGreen.withOpacity(0.06)
              : ColorPalette.backgroundGray,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: uploaded
                ? ColorPalette.accentGreen.withOpacity(0.45)
                : ColorPalette.border,
            width: uploaded ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              uploaded ? Icons.check_circle_outline_rounded : icon,
              color: uploaded
                  ? ColorPalette.accentGreen
                  : ColorPalette.secondaryLight,
              size: 22.sp,
            ),
            SizedBox(height: 6.h),
            Text(
              uploaded ? (fileName ?? 'Uploaded') : 'Tap to Upload',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: uploaded
                    ? ColorPalette.accentGreen
                    : ColorPalette.secondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: ColorPalette.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _fieldLabel(String label, {bool required = false}) => RichText(
    text: TextSpan(
      text: label,
      style: AppTextStyles.bodyMedium.copyWith(
        color: ColorPalette.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      children: required
          ? [
              TextSpan(
                text: ' *',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: ColorPalette.error,
                ),
              ),
            ]
          : [],
    ),
  );

  Widget _styledDropdown({
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) => Container(
    padding: EdgeInsets.symmetric(horizontal: 14.w),
    decoration: BoxDecoration(
      color: ColorPalette.surfaceGray,
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(color: ColorPalette.border),
    ),
    child: Row(
      children: [
        Icon(icon, color: ColorPalette.secondary, size: 20.sp),
        SizedBox(width: 8.w),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                hint,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: ColorPalette.textLight,
                ),
              ),
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: ColorPalette.textSecondary,
                size: 18.sp,
              ),
              style: AppTextStyles.bodyMedium.copyWith(
                color: ColorPalette.textPrimary,
              ),
              dropdownColor: ColorPalette.surface,
              borderRadius: BorderRadius.circular(12.r),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _navActions() => Column(
    children: [
      CustomButton(
        title: 'Continue',
        onPressed: _next,
        suffixIcon: Icons.arrow_forward_rounded,
        backgroundColor: ColorPalette.secondary,
      ),
      SizedBox(height: 10.h),
      _prevButton(),
    ],
  );

  Widget _prevButton() => OutlinedCustomButton(
    title: 'Previous',
    onPressed: _prev,
    icon: Icons.arrow_back_rounded,
    borderColor: ColorPalette.secondary,
  );
}
