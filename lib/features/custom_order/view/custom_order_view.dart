import 'package:atompro/core/common/widgets/app_bar.dart';
import 'package:atompro/core/common/widgets/custom_button.dart';
import 'package:atompro/core/common/widgets/custom_drop_down.dart';
import 'package:atompro/core/common/widgets/custom_text_field.dart';
import 'package:atompro/core/style/app_text_styles.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:atompro/core/style/extensions.dart';
import 'package:atompro/features/city_area_selector/view/city_area_selector_view.dart';
import 'package:atompro/features/custom_order/viewmodel/custom_order_viewmodel.dart';
import 'package:atompro/features/drawer/view/drawer.dart';
import 'package:atompro/features/home/view/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

enum _Phase { calculator, planReview, personalDetails }

class CustomOrderView extends ConsumerStatefulWidget {
  const CustomOrderView({super.key});

  @override
  ConsumerState<CustomOrderView> createState() => _CustomOrderViewState();
}

class _CustomOrderViewState extends ConsumerState<CustomOrderView>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollCtrl = ScrollController();

  _Phase _phase = _Phase.calculator;

  // Controllers — owned here, never recreated
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _advanceCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  String? _selectedMonth;

  late final AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(customOrderViewModelProvider, (prev, next) {
        if (next.isSuccess && !(prev?.isSuccess ?? false)) {
          _showSuccessDialog();
        }
      });
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scrollCtrl.dispose();
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _advanceCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  void _goToPhase(_Phase next) {
    _fadeCtrl.reverse().then((_) {
      setState(() => _phase = next);
      _scrollCtrl.jumpTo(0);
      _fadeCtrl.forward();
    });
  }

  void _calculatePlan() {
    ref.read(customOrderViewModelProvider.notifier).calculatePlan();
    final state = ref.read(customOrderViewModelProvider);
    if (state.plans.isNotEmpty && state.errorMessage == null) {
      _goToPhase(_Phase.planReview);
    } else if (state.errorMessage != null) {
      _showErrorSnack(state.errorMessage!);
    }
  }

  Future<void> _submitOrder() async {
    await ref.read(customOrderViewModelProvider.notifier).submit();
    final state = ref.read(customOrderViewModelProvider);
    if (state.errorMessage != null && !state.isSuccess) {
      _showErrorSnack(state.errorMessage!);
    }
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Order Submitted!',
              style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Our agent will contact you within 24–48 hours for verification and delivery.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: ColorPalette.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              title: 'Back to Home',
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => HomePage()),
                  (route) => false,
                );
              },
              backgroundColor: ColorPalette.secondary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: ColorPalette.backgroundGray,
      drawer: AppDrawer(),
      appBar: buildAppBar(
        context,
        () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: Column(
        children: [
          _PhaseIndicator(phase: _phase),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
                child: _buildPhase(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhase() {
    switch (_phase) {
      case _Phase.calculator:
        return _CalculatorPhase(
          titleCtrl: _titleCtrl,
          priceCtrl: _priceCtrl,
          advanceCtrl: _advanceCtrl,
          selectedMonth: _selectedMonth,
          onMonthChanged: (v) => setState(() => _selectedMonth = v),
          onCalculate: _calculatePlan,
        );
      case _Phase.planReview:
        return Consumer(
          builder: (_, ref, __) {
            final state = ref.watch(customOrderViewModelProvider);
            return _PlanReviewPhase(
              state: state,
              onBack: () => _goToPhase(_Phase.calculator),
              onProceed: () => _goToPhase(_Phase.personalDetails),
            );
          },
        );
      case _Phase.personalDetails:
        return _PersonalPhase(
          nameCtrl: _nameCtrl,
          phoneCtrl: _phoneCtrl,
          addressCtrl: _addressCtrl,
          refCtrl: _refCtrl,
          onBack: () => _goToPhase(_Phase.planReview),
          onSubmit: _submitOrder,
        );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Phase Indicator
// ═══════════════════════════════════════════════════════════════════════════

class _PhaseIndicator extends StatelessWidget {
  final _Phase phase;
  const _PhaseIndicator({required this.phase});

  @override
  Widget build(BuildContext context) {
    final steps = ['Calculator', 'Plan Review', 'Your Details'];
    final idx = _Phase.values.indexOf(phase);

    return Container(
      color: ColorPalette.surface,
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 14.h),
      child: Column(
        children: [
          Row(
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: 2,
                    color: (i ~/ 2) < idx
                        ? ColorPalette.secondary
                        : ColorPalette.border,
                  ),
                );
              }
              final si = i ~/ 2;
              final done = si < idx;
              final active = si == idx;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: active ? 32 : 26,
                height: active ? 32 : 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done || active
                      ? ColorPalette.secondary
                      : ColorPalette.backgroundGray,
                  border: Border.all(
                    color: done || active
                        ? ColorPalette.secondary
                        : ColorPalette.border,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: done
                      ? Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 13.sp,
                        )
                      : Text(
                          '${si + 1}',
                          style: AppTextStyles.caption.copyWith(
                            color: active
                                ? Colors.white
                                : ColorPalette.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              );
            }),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (i) {
              final active = i == idx;
              final done = i < idx;
              return Text(
                steps[i],
                style: AppTextStyles.caption.copyWith(
                  color: done || active
                      ? ColorPalette.secondary
                      : ColorPalette.textSecondary,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Phase 1 — Calculator
// ═══════════════════════════════════════════════════════════════════════════

class _CalculatorPhase extends ConsumerWidget {
  final TextEditingController titleCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController advanceCtrl;
  final String? selectedMonth;
  final ValueChanged<String?> onMonthChanged;
  final VoidCallback onCalculate;

  const _CalculatorPhase({
    required this.titleCtrl,
    required this.priceCtrl,
    required this.advanceCtrl,
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.onCalculate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorMessage = ref.watch(
      customOrderViewModelProvider.select((s) => s.errorMessage),
    );
    final vm = ref.read(customOrderViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Order & Installment Calculator',
          style: AppTextStyles.h4,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 6.h),
        Text(
          'Enter product details to instantly calculate transparent installment plans.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: ColorPalette.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20.h),

        _Card(
          children: [
            _SectionHeader(
              icon: Icons.shopping_cart_outlined,
              title: 'Product Details',
              color: ColorPalette.accentRed,
            ),
            SizedBox(height: 20.h),
            CustomTextField(
              controller: titleCtrl,
              filled: false,
              labelText: 'PRODUCT TITLE',
              hintText: 'e.g. iPhone 15 Pro Max',
              onChanged: vm.updateProductTitle,
            ),
            SizedBox(height: 16.h),
            CustomTextField(
              controller: priceCtrl,
              filled: false,
              labelText: 'PRODUCT PRICE',
              prefixIcon: const Center(widthFactor: 1, child: Text('RS.')),
              hintText: '0.00',
              keyboardType: TextInputType.number,
              onChanged: vm.updateProductPrice,
            ),
            SizedBox(height: 16.h),
            CustomTextField(
              controller: advanceCtrl,
              filled: false,
              labelText: 'ADVANCE PAYMENT (Min 20%)',
              prefixIcon: const Center(widthFactor: 1, child: Text('RS.')),
              hintText: '0.00',
              keyboardType: TextInputType.number,
              onChanged: vm.updateAdvancePrice,
            ),
            SizedBox(height: 16.h),
            CustomSearchDropdown(
              selectedItem: selectedMonth,
              surfaceColor: Colors.transparent,
              labelText: 'INSTALLMENT TENURE',
              items: const [
                '3 Months',
                '4 Months',
                '5 Months',
                '6 Months',
                '7 Months',
                '8 Months',
                '9 Months',
                '10 Months',
                '11 Months',
                '12 Months',
              ],
              itemAsString: (item) => item,
              onChanged: (val) {
                if (val != null) {
                  vm.updateMonths(int.tryParse(val.split(' ')[0]) ?? 3);
                  onMonthChanged(val);
                }
              },
            ),
            if (errorMessage != null) ...[
              SizedBox(height: 16.h),
              _ErrorBox(message: errorMessage),
            ],
            SizedBox(height: 24.h),
            CustomButton(
              title: 'Calculate Plan',
              onPressed: onCalculate,
              suffixIcon: Icons.calculate_outlined,
              backgroundColor: ColorPalette.accentRed,
            ),
          ],
        ),

        SizedBox(height: 16.h),
        const _ByProceedingWidget(),
        SizedBox(height: 24.h),
        _WhyChooseUsSection(),
        SizedBox(height: 16.h),
        _ConvenienceSection(),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Phase 2 — Plan Review
// ═══════════════════════════════════════════════════════════════════════════

class _PlanReviewPhase extends StatelessWidget {
  final CustomOrderState state;
  final VoidCallback onBack;
  final VoidCallback onProceed;

  const _PlanReviewPhase({
    required this.state,
    required this.onBack,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    final plan = state.plans.first;
    final feeLabel = state.hasDiscount
        ? '0.5% (Ref Discount)'
        : '1% (Standard)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product recap pill
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: ColorPalette.backgroundBlueLight,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: ColorPalette.secondary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: ColorPalette.secondary,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  state.productTitle.isEmpty
                      ? 'Your Product'
                      : state.productTitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.secondary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onBack,
                child: Text(
                  'Edit',
                  style: AppTextStyles.caption.copyWith(
                    color: ColorPalette.secondaryLight,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        _Card(
          children: [
            _SectionHeader(
              icon: Icons.payments_outlined,
              title: 'Your Installment Plan',
              color: ColorPalette.secondary,
            ),
            SizedBox(height: 20.h),

            // Gradient monthly amount
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A3277), ColorPalette.secondaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Monthly Installment',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          '4% FIXED',
                          style: AppTextStyles.overline.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rs.',
                        style: AppTextStyles.h5.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        plan.amount.toStringAsFixed(0),
                        style: AppTextStyles.h2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        ' /month',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'for ${state.installmentMonths} months',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),
            _SummaryRow(
              label: 'Product Price',
              value: 'Rs. ${state.productPrice.toStringAsFixed(0)}',
            ),
            const _Divider(),
            _SummaryRow(
              label: 'Down Payment',
              value: 'Rs. ${state.advancePrice.toStringAsFixed(0)}',
            ),
            const _Divider(),
            // Sourcing fee row — shows rate clearly
            _SummaryRow(
              label: 'Sourcing Agent Fee ($feeLabel)',
              value: 'Rs. ${state.sourcingFee.toStringAsFixed(0)}',
              valueColor: state.hasDiscount ? ColorPalette.accentGreen : null,
            ),
            const _Divider(),
            _SummaryRow(
              label: 'Total Deal Amount',
              value: 'Rs. ${state.totalPayable.toStringAsFixed(0)}',
              isTotal: true,
            ),

            // Discount badge if active
            if (state.hasDiscount) ...[
              SizedBox(height: 12.h),
              _DiscountBadge(),
            ],

            SizedBox(height: 24.h),
            CustomButton(
              title: 'Proceed to Personal Details',
              onPressed: onProceed,
              suffixIcon: Icons.arrow_forward_rounded,
              backgroundColor: ColorPalette.secondary,
            ),
            SizedBox(height: 12.h),
            OutlinedCustomButton(
              title: 'Edit Product Details',
              onPressed: onBack,
              icon: Icons.arrow_back_rounded,
              borderColor: ColorPalette.secondary,
            ),
          ],
        ),

        SizedBox(height: 16.h),
        const _ByProceedingWidget(),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Phase 3 — Personal Details + Order Summary
// ═══════════════════════════════════════════════════════════════════════════

class _PersonalPhase extends ConsumerWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController refCtrl;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const _PersonalPhase({
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.addressCtrl,
    required this.refCtrl,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Granular selects — only rebuild what changes
    final isSubmitting = ref.watch(
      customOrderViewModelProvider.select((s) => s.isSubmitting),
    );
    final isValidating = ref.watch(
      customOrderViewModelProvider.select((s) => s.isValidatingRefCode),
    );
    final isRefValid = ref.watch(
      customOrderViewModelProvider.select((s) => s.isRefCodeValid),
    );
    final hasDiscount = ref.watch(
      customOrderViewModelProvider.select((s) => s.hasDiscount),
    );
    final state = ref.watch(customOrderViewModelProvider);
    final vm = ref.read(customOrderViewModelProvider.notifier);

    final feeLabel = hasDiscount ? '0.5% (Ref Discount)' : '1% (Standard)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Plan recap banner ──────────────────────────────────────────────
        if (state.plans.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3277), ColorPalette.secondaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Installment',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Rs. ${state.plans.first.amount.toStringAsFixed(0)} /mo',
                      style: AppTextStyles.h5.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${state.installmentMonths} months',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    GestureDetector(
                      onTap: onBack,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'Change Plan',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        SizedBox(height: 16.h),

        // ── Personal Details ───────────────────────────────────────────────
        _Card(
          children: [
            _SectionHeader(
              icon: Icons.person_outline,
              title: 'Personal Details',
              color: ColorPalette.secondary,
            ),
            SizedBox(height: 20.h),
            CustomTextField(
              controller: nameCtrl,
              labelText: 'FULL NAME',
              hintText: 'Enter your full name',
              onChanged: vm.updateFullName,
            ),
            SizedBox(height: 16.h),
            CustomTextField(
              controller: phoneCtrl,
              labelText: 'PHONE NUMBER',
              hintText: '03xx-xxxxxxx',
              keyboardType: TextInputType.phone,
              onChanged: vm.updatePhone,
            ),
            SizedBox(height: 16.h),
            const CityAreaWidget(),
            SizedBox(height: 16.h),
            CustomTextField(
              controller: addressCtrl,
              labelText: 'RESIDENTIAL ADDRESS',
              hintText: 'House #, Street #, Sector',
              onChanged: vm.updateAddress,
            ),
            SizedBox(height: 16.h),

            // ── Ref code field with live validation indicator ───────────────
            Text(
              'SUPPLIER REFERENCE',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Stack(
              children: [
                CustomTextField(
                  controller: refCtrl,
                  hintText: 'Optional — reduces sourcing fee to 0.5%',
                  onChanged: vm.updateRefCode, // debounced inside vm
                ),
                // Validation status icon overlaid on the right
                Positioned(
                  right: 14,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _RefCodeStatus(
                      isValidating: isValidating,
                      isValid: isRefValid,
                      hasText: refCtrl.text.isNotEmpty,
                    ),
                  ),
                ),
              ],
            ),

            // Result feedback below field
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: !isValidating && refCtrl.text.isNotEmpty
                  ? Padding(
                      key: ValueKey(isRefValid),
                      padding: EdgeInsets.only(top: 8.h),
                      child: isRefValid ? _DiscountBadge() : _InvalidRefBadge(),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // ── Order Summary ──────────────────────────────────────────────────
        if (state.plans.isNotEmpty)
          _Card(
            children: [
              _SectionHeader(
                icon: Icons.receipt_long_outlined,
                title: 'Order Summary',
                color: ColorPalette.secondary,
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      state.productTitle.isEmpty
                          ? 'Your Product'
                          : state.productTitle,
                      style: AppTextStyles.h6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: ColorPalette.backgroundGray,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '${state.installmentMonths} Installments',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1),
              ),
              _SummaryRow(
                label: 'Monthly Installment',
                value: 'Rs. ${state.plans.first.amount.toStringAsFixed(0)}',
                valueColor: ColorPalette.secondary,
                isBold: true,
              ),
              const _Divider(),
              _SummaryRow(
                label: 'Product Price',
                value: 'Rs. ${state.productPrice.toStringAsFixed(0)}',
              ),
              const _Divider(),
              _SummaryRow(
                label: 'Down Payment',
                value: 'Rs. ${state.advancePrice.toStringAsFixed(0)}',
              ),
              const _Divider(),
              _SummaryRow(
                label: 'Sourcing Fee ($feeLabel)',
                value: 'Rs. ${state.sourcingFee.toStringAsFixed(0)}',
                valueColor: hasDiscount ? ColorPalette.accentGreen : null,
              ),
              const _Divider(),
              _SummaryRow(
                label: 'Total Payable',
                value: 'Rs. ${state.totalPayable.toStringAsFixed(0)}',
                isTotal: true,
              ),
              SizedBox(height: 24.h),
              CustomButton(
                title: isSubmitting ? 'Confirming...' : 'Confirm Order',
                onPressed: isSubmitting ? null : onSubmit,
                suffixIcon: Icons.check_circle_outline_rounded,
                backgroundColor: ColorPalette.secondary,
              ),
              SizedBox(height: 12.h),
              OutlinedCustomButton(
                title: 'Back to Plan Review',
                onPressed: onBack,
                icon: Icons.arrow_back_rounded,
                borderColor: ColorPalette.secondary,
              ),
            ],
          ),

        SizedBox(height: 16.h),
        const _ByProceedingWidget(),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Ref code status icon
// ═══════════════════════════════════════════════════════════════════════════

class _RefCodeStatus extends StatelessWidget {
  final bool isValidating;
  final bool isValid;
  final bool hasText;
  const _RefCodeStatus({
    required this.isValidating,
    required this.isValid,
    required this.hasText,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasText) return const SizedBox.shrink();
    if (isValidating) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(ColorPalette.secondary),
        ),
      );
    }
    return Icon(
      isValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
      color: isValid ? ColorPalette.accentGreen : ColorPalette.error,
      size: 20,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared micro-widgets
// ═══════════════════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: ColorPalette.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE4E7EA)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 12),
      Text(title, style: AppTextStyles.h6),
    ],
  );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isTotal
                ? ColorPalette.textPrimary
                : ColorPalette.textSecondary,
            fontWeight: isTotal || isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
      Text(
        value,
        style: AppTextStyles.bodyBold.copyWith(
          fontSize: isTotal ? 18 : 14,
          fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
          color:
              valueColor ??
              (isTotal ? ColorPalette.textPrimary : ColorPalette.textPrimary),
        ),
      ),
    ],
  );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: Divider(height: 1),
  );
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DiscountBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: ColorPalette.accentGreen.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: ColorPalette.accentGreen.withOpacity(0.4)),
    ),
    child: Row(
      children: [
        Icon(
          Icons.local_offer_rounded,
          color: ColorPalette.accentGreen,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Ref code applied! Sourcing fee reduced from 1% → 0.5%',
            style: AppTextStyles.caption.copyWith(
              color: ColorPalette.accentGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _InvalidRefBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: ColorPalette.error.withOpacity(0.06),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: ColorPalette.error.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline_rounded, color: ColorPalette.error, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Invalid reference code. Standard 1% fee applies.',
            style: AppTextStyles.caption.copyWith(
              color: ColorPalette.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ByProceedingWidget extends StatelessWidget {
  const _ByProceedingWidget();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: ColorPalette.backgroundBlueLight,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info, color: ColorPalette.secondary, size: 18),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            'By proceeding, you agree to our terms. Our agent will visit your address within 24–48 hours for physical verification.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: ColorPalette.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Static info sections ───────────────────────────────────────────────────

class _WhyChooseUsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPalette.backgroundBlueLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorPalette.secondary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: ColorPalette.secondary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Why choose these plans?',
                style: AppTextStyles.bodyBold.copyWith(
                  color: ColorPalette.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _item(
            Icons.security_outlined,
            'Zero Hidden Fees',
            'Transparent pricing. No extra charges at any stage.',
          ),
          _item(
            Icons.calendar_today_outlined,
            'Flexible Tenure',
            'Pay early with zero penalty. Choose what fits your pocket.',
          ),
          _item(
            Icons.admin_panel_settings_outlined,
            'Secured & Insured',
            'Electronics covered under our base insurance policy.',
          ),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String title, String desc) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4),
            ],
          ),
          child: Icon(icon, color: ColorPalette.secondary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
              const SizedBox(height: 3),
              Text(desc, style: AppTextStyles.bodySmall.copyWith(height: 1.4)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ConvenienceSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.auto_awesome_mosaic_outlined,
        'Custom Instalment Plans',
        'Flexible tenures from 3 to 12 months tailored to your budget.',
      ),
      (
        Icons.fact_check_outlined,
        'Easy Verification',
        'Minimal docs required. Get verified in minutes, not days.',
      ),
      (
        Icons.hail_outlined,
        'Doorstep Service',
        'From docs to delivery — we handle everything at your door.',
      ),
      (
        Icons.travel_explore_outlined,
        'Any Product Sourced',
        "Can't find it? We source any product locally or internationally.",
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FAFA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Designed For Your Convenience',
            style: AppTextStyles.h6.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "We've removed the hurdles of traditional financing.",
            style: AppTextStyles.bodySmall.copyWith(height: 1.5),
          ),
          const SizedBox(height: 24),
          ...items.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: ColorPalette.secondary.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(e.$1, color: ColorPalette.secondary, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.$2,
                          style: AppTextStyles.bodyBold.copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          e.$3,
                          style: AppTextStyles.bodySmall.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
