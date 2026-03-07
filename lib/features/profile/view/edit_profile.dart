import 'package:atompro/core/common/widgets/custom_button.dart';
import 'package:atompro/core/common/widgets/custom_text_field.dart';
import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:atompro/features/city_area_selector/view/city_area_selector_view.dart';
import 'package:atompro/features/city_area_selector/viewmodel/city_area_viewmodel.dart';
import 'package:atompro/features/profile/viewmodel/profile_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [isCompletionFlow] = true  → user redirected here after login because
///                               required fields were missing. Back button
///                               hidden; after save → Home.
/// [isCompletionFlow] = false → user opened "Edit Profile" from Profile page.
///                               Back button shown; after save → back.
class EditProfilePage extends ConsumerStatefulWidget {
  final bool isCompletionFlow;

  const EditProfilePage({super.key, this.isCompletionFlow = false});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _initialised = false;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _prefillControllers(ProfileEditState s) {
    if (_initialised) return;
    _initialised = true;
    _nameCtrl.text = s.name ?? '';
    _phoneCtrl.text = s.phone ?? '';
    _emailCtrl.text = s.email ?? '';
    _addressCtrl.text = s.address ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileViewModelProvider);
    final cityAreaState = ref.watch(cityAreaViewModelProvider);
    final cityAreaNotifier = ref.read(cityAreaViewModelProvider.notifier);

    // Pre-fill text fields once session data is loaded
    if (!profileState.isLoading) {
      _prefillControllers(profileState);

      // Auto-select city if not yet selected and we have a stored cityId
      if (cityAreaState.selectedCity == null &&
          profileState.cityId != null &&
          profileState.cityId != 'null' &&
          cityAreaState.cities.isNotEmpty) {
        final storedCityId = int.tryParse(profileState.cityId ?? '');
        if (storedCityId != null) {
          final match = cityAreaState.cities.where((c) => c.id == storedCityId);
          if (match.isNotEmpty) {
            Future.microtask(() => cityAreaNotifier.onCityChanged(match.first));
          }
        }
      }

      // Auto-select area after areas have loaded
      if (cityAreaState.selectedArea == null &&
          profileState.areaId != null &&
          profileState.areaId != 'null' &&
          cityAreaState.areas.isNotEmpty) {
        final storedAreaId = int.tryParse(profileState.areaId ?? '');
        if (storedAreaId != null) {
          final match = cityAreaState.areas.where((a) => a.id == storedAreaId);
          if (match.isNotEmpty) {
            Future.microtask(() => cityAreaNotifier.onAreaChanged(match.first));
          }
        }
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F5FB),
        body: profileState.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: ColorPalette.secondary),
              )
            : FadeTransition(
                opacity: _fadeIn,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // ── Completion banner ────────────────────────────
                          if (widget.isCompletionFlow) ...[
                            const _CompletionBanner(),
                            const SizedBox(height: 24),
                          ],

                          // ── Personal Info ────────────────────────────────
                          _sectionLabel('Personal Info'),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _nameCtrl,
                            labelText: 'Full Name',
                            hintText: 'Enter your full name',
                            keyboardType: TextInputType.name,
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                              size: 20,
                              color: ColorPalette.secondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            controller: _phoneCtrl,
                            labelText: 'Phone Number',
                            hintText: 'Enter your phone number',
                            keyboardType: TextInputType.phone,
                            prefixIcon: const Icon(
                              Icons.phone_outlined,
                              size: 20,
                              color: ColorPalette.secondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            controller: _emailCtrl,
                            labelText: 'Email',
                            hintText: 'Enter your email address',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              size: 20,
                              color: ColorPalette.secondary,
                            ),
                          ),

                          // ── Delivery Info ────────────────────────────────
                          const SizedBox(height: 24),
                          _sectionLabel('Delivery Info'),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _addressCtrl,
                            labelText: 'Address',
                            hintText: 'Enter your full address',
                            keyboardType: TextInputType.streetAddress,
                            maxLines: 3,
                            prefixIcon: const Icon(
                              Icons.location_on_outlined,
                              size: 20,
                              color: ColorPalette.secondary,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // ── City & Area dropdowns ────────────────────────
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF213F9A,
                                  ).withOpacity(0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const CityAreaWidget(),
                          ),

                          // ── Save button ──────────────────────────────────
                          const SizedBox(height: 32),
                          CustomButton(
                            title: 'Save Profile',
                            isLoading: profileState.isSaving,
                            onPressed: profileState.isSaving
                                ? null
                                : () {
                                    HapticFeedback.mediumImpact();
                                    ref
                                        .read(profileViewModelProvider.notifier)
                                        .saveProfile(
                                          name: _nameCtrl.text,
                                          phone: _phoneCtrl.text,
                                          email: _emailCtrl.text,
                                          address: _addressCtrl.text,
                                          selectedCity:
                                              cityAreaState.selectedCity,
                                          selectedArea:
                                              cityAreaState.selectedArea,
                                          isCompletionFlow:
                                              widget.isCompletionFlow,
                                        );
                                  },
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Row(
          children: [
            if (!widget.isCompletionFlow) ...[
              GestureDetector(
                onTap: () => AppNavigator.getBack(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_rounded,
                    size: 18,
                    color: ColorPalette.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Text(
              widget.isCompletionFlow
                  ? 'Complete Your Profile'
                  : 'Edit Profile',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: ColorPalette.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section label ────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 2),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: ColorPalette.secondary,
        letterSpacing: 2.2,
      ),
    ),
  );
}

// ── Completion Banner ──────────────────────────────────────────────────────────
class _CompletionBanner extends StatelessWidget {
  const _CompletionBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: ColorPalette.secondaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: ColorPalette.secondary.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.assignment_ind_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Almost there!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Please complete your profile to continue.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
