import 'package:atompro/core/common/widgets/custom_button.dart';
import 'package:atompro/core/common/widgets/custom_text_field.dart';
import 'package:atompro/core/style/app_text_styles.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:atompro/features/city_area_selector/view/city_area_selector_view.dart';
import 'package:atompro/features/smart_seller/viewmodel/smart_seller_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class SmartSellerForm extends ConsumerStatefulWidget {
  const SmartSellerForm({super.key});

  @override
  ConsumerState<SmartSellerForm> createState() => _SmartSellerFormState();
}

class _SmartSellerFormState extends ConsumerState<SmartSellerForm>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  final _pageCtrl = PageController();
  late final AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  // ── Controllers ───────────────────────────────────────────────────────────

  // Step 1
  final _nameCtrl = TextEditingController();
  final _bizNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // Step 2
  final _cnicCtrl = TextEditingController();
  final _ntnCtrl = TextEditingController();
  String? _bizType;
  String? _investmentCapacity;

  final _bizTypes = const [
    'Individual',
    'Retailer',
    'Wholesaler',
    'Manufacturer',
    'Partnership',
    'Other',
  ];

  final _investmentOptions = const [
    'Less than 500K',
    '500K - 1 Million',
    '1 Million - 2.5 Million',
    '2.5 Million - 5 Million',
    '5 Million+',
  ];

  // Step 3
  final _addressCtrl = TextEditingController();

  // Step 4
  final _regNumCtrl = TextEditingController();

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = ref.read(smartSellerViewmodelProvider.notifier);
      _nameCtrl.addListener(() => vm.updateName(_nameCtrl.text));
      _bizNameCtrl.addListener(() => vm.updateBusinessName(_bizNameCtrl.text));
      _phoneCtrl.addListener(() => vm.updatePhone(_phoneCtrl.text));
      _whatsappCtrl.addListener(() => vm.updateWhatsapp(_whatsappCtrl.text));
      _emailCtrl.addListener(() => vm.updateEmail(_emailCtrl.text));
      _passCtrl.addListener(() => vm.updatePassword(_passCtrl.text));
      _cnicCtrl.addListener(() => vm.updateCnic(_cnicCtrl.text));
      _ntnCtrl.addListener(() => vm.updateNtn(_ntnCtrl.text));
      _addressCtrl.addListener(() => vm.updateAddress(_addressCtrl.text));
      _regNumCtrl.addListener(() => vm.updateRegNumber(_regNumCtrl.text));
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _progressCtrl.dispose();
    _nameCtrl.dispose();
    _bizNameCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _cnicCtrl.dispose();
    _ntnCtrl.dispose();
    _addressCtrl.dispose();
    _regNumCtrl.dispose();
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

  /// Validates current step before advancing.
  void _next() {
    final vm = ref.read(smartSellerViewmodelProvider.notifier);
    final error = vm.validateStep(_step);
    if (error != null) {
      _showErrorSnack(error);
      return;
    }
    if (_step < _total - 1) _goTo(_step + 1);
  }

  void _prev() {
    if (_step > 0) _goTo(_step - 1);
  }

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

  Future<void> _submit() async {
    // Final step validation first
    final vm = ref.read(smartSellerViewmodelProvider.notifier);
    final error = vm.validateStep(_step);
    if (error != null) {
      _showErrorSnack(error);
      return;
    }

    await vm.submit();

    // Check result
    final state = ref.read(smartSellerViewmodelProvider);
    if (state.isSuccess) {
      _showSuccessDialog(
        code: state.successCode ?? '',
        message: state.successMessage ?? 'Your registration is under review.',
      );
    } else if (state.errorMessage != null) {
      _showErrorSnack(state.errorMessage!);
    }
  }

  void _showSuccessDialog({required String code, required String message}) {
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
              // Success icon
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

              if (code.isNotEmpty) ...[
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: ColorPalette.backgroundBlueLight,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: ColorPalette.secondary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.confirmation_number_outlined,
                        color: ColorPalette.secondary,
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        code,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: ColorPalette.secondary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Save this code for reference',
                  style: AppTextStyles.caption.copyWith(
                    color: ColorPalette.textSecondary,
                  ),
                ),
              ],

              SizedBox(height: 24.h),
              CustomButton(
                title: 'Done',
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  Navigator.of(context).pop(); // back to previous screen
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
    final labels = ['Personal', 'Business', 'Location', 'Verify'];
    final icons = [
      Icons.person_outline_rounded,
      Icons.business_center_outlined,
      Icons.location_on_outlined,
      Icons.verified_outlined,
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
                    'Smart Seller Program',
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
                    'Partner with Us —\nGrow Your Business',
                    style: AppTextStyles.h4.copyWith(
                      color: ColorPalette.textWhite,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'بغیر کسی رسک کے اپنا کاروبار بڑھائیں',
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

  Widget _step1() {
    return _shell(
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
          controller: _whatsappCtrl,
          labelText: 'WhatsApp Number',
          hintText: 'Same as phone if same',
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          prefixIcon: Icon(
            Icons.chat_outlined,
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
  }

  // ── Step 2 — Business Details ──────────────────────────────────────────────

  Widget _step2() {
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
        CustomTextField(
          controller: _ntnCtrl,
          labelText: 'NTN / Tax Number',
          hintText: 'If applicable',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          prefixIcon: Icon(
            Icons.receipt_long_outlined,
            color: ColorPalette.secondary,
            size: 20,
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
            ref
                .read(smartSellerViewmodelProvider.notifier)
                .updateBusinessType(v);
          },
        ),
        SizedBox(height: 16.h),
        _fieldLabel('Investment Capacity'),
        SizedBox(height: 8.h),
        _styledDropdown(
          hint: 'Select investment range',
          icon: Icons.account_balance_wallet_outlined,
          value: _investmentCapacity,
          items: _investmentOptions,
          onChanged: (v) {
            setState(() => _investmentCapacity = v);
            ref.read(smartSellerViewmodelProvider.notifier).updateInvestment(v);
          },
        ),
      ],
      actions: _navActions(),
    );
  }

  // ── Step 3 — Location ──────────────────────────────────────────────────────

  Widget _step3() {
    return _shell(
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
  }

  // ── Step 4 — Business Verification ────────────────────────────────────────

  Widget _step4() {
    final isSubmitting = ref.watch(
      smartSellerViewmodelProvider.select((s) => s.isSubmitting),
    );

    return _shell(
      title: 'Business Verification',
      subtitle: 'Final details for KYC review by AtomShop Team',
      fields: [
        // Info banner
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
                  'Our team will review your application within 24–48 hours.',
                  style: AppTextStyles.caption.copyWith(
                    color: ColorPalette.secondaryLight,
                  ),
                ),
              ),
            ],
          ),
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
      actions: Column(
        children: [
          CustomButton(
            title: isSubmitting ? 'Submitting...' : 'Submit Application',
            onPressed: isSubmitting ? null : _submit,
            suffixIcon: Icons.send_rounded,
            backgroundColor: ColorPalette.secondary,
          ),
          SizedBox(height: 10.h),
          _prevButton(),
        ],
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
