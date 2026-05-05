import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:atompro/core/style/color_palette.dart';

class TermsOfUse extends StatelessWidget {
  const TermsOfUse({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F5FB),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _backBtn(context),
                          const SizedBox(width: 14),
                          const Text(
                            'Terms of Use',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: ColorPalette.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Hero card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: ColorPalette.secondaryGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: ColorPalette.secondary.withOpacity(0.26),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.gavel_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'End User License Agreement',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'For AtomShop Mobile App — please read carefully before using.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Content ───────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _section(
                    number: '1',
                    title: 'License Grant',
                    bullets: [
                      'Download, install, and use the app solely for your personal, non-commercial use on a device you own or control.',
                      'Use the app in accordance with this agreement.',
                    ],
                  ),
                  const SizedBox(height: 12),

                  _section(
                    number: '2',
                    title: 'Restrictions',
                    bullets: [
                      'Use the app for any unlawful or fraudulent purpose.',
                      'Copy, modify, reverse engineer, or distribute any part of the app.',
                      'Sell, sublicense, or commercially exploit the app.',
                      'Interfere with the performance of the app or related services.',
                    ],
                  ),
                  const SizedBox(height: 12),

                  _section(
                    number: '3',
                    title: 'Ownership',
                    text:
                        'All rights, title, and interest in the app remain the property of Atom Services (Private) Limited. This agreement grants no ownership rights.',
                  ),
                  const SizedBox(height: 12),

                  _section(
                    number: '4',
                    title: 'User Data and Privacy',
                    bullets: [
                      'You must provide accurate info for identity and installment verification.',
                      'Your data may be collected and used for processing, evaluation, or recovery per our Privacy Policy.',
                    ],
                  ),
                  const SizedBox(height: 12),

                  _section(
                    number: '5',
                    title: 'Third-Party Services',
                    text:
                        'The app may interact with services like WhatsApp or Google Maps. You agree to comply with their terms.',
                  ),
                  const SizedBox(height: 12),

                  _section(
                    number: '6',
                    title: 'Installment Terms',
                    bullets: [
                      'Installment approvals are subject to manual verification.',
                      'Payments must be made via approved methods (e.g., bank transfer, cash collection).',
                      'AtomShop reserves the right to pursue recovery actions in case of non-payment.',
                    ],
                  ),
                  const SizedBox(height: 12),

                  _section(
                    number: '7',
                    title: 'Termination',
                    bullets: [
                      'AtomShop may terminate your access if you breach terms or laws, or fail installment/verification requirements.',
                      'Upon termination, you must stop using and delete the app.',
                    ],
                  ),
                  const SizedBox(height: 12),

                  _section(
                    number: '8',
                    title: 'Disclaimer of Warranties',
                    bullets: [
                      'The app is provided "as is" without any warranties.',
                      'We do not guarantee uninterrupted service or delivery times.',
                    ],
                  ),
                  const SizedBox(height: 12),

                  _section(
                    number: '9',
                    title: 'Limitation of Liability',
                    bullets: [
                      'AtomShop is not liable for indirect or consequential damages.',
                      'We are not responsible for delays in verification, delivery, or payments.',
                    ],
                  ),
                  const SizedBox(height: 12),

                  _section(
                    number: '10',
                    title: 'Governing Law',
                    text:
                        'This agreement is governed by Pakistani law. Disputes will be handled in courts located in Lahore.',
                  ),
                  const SizedBox(height: 12),

                  // Section 11 — Contact
                  _card(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECF0FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              '11',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: ColorPalette.secondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contact',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: ColorPalette.textPrimary,
                                ),
                              ),
                              SizedBox(height: 10),
                              _ContactRow(
                                icon: Icons.phone_outlined,
                                label: '+92 2277522',
                              ),
                              SizedBox(height: 8),
                              _ContactRow(
                                icon: Icons.email_outlined,
                                label: 'support@atomshop.pk',
                              ),
                              SizedBox(height: 8),
                              _ContactRow(
                                icon: Icons.location_on_outlined,
                                label:
                                    '206 Nasheman Iqbal, Phase 1, Lahore, Pakistan',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Footer
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: ColorPalette.secondary.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ColorPalette.secondary.withOpacity(0.18),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: ColorPalette.secondary,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'By using the AtomShop app, you agree to this EULA.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ColorPalette.secondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _section({
    required String number,
    required String title,
    String? text,
    List<String>? bullets,
  }) {
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFECF0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: ColorPalette.secondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: ColorPalette.textPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 8),
                if (text != null) _body(text),
                if (bullets != null) ...bullets.map(_bulletItem),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: ColorPalette.secondary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(child: _body(text)),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF213F9A).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _body(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13.5,
      color: ColorPalette.textSecondary,
      height: 1.6,
    ),
  );

  Widget _backBtn(BuildContext context) => GestureDetector(
    onTap: () => Navigator.pop(context),
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
        Icons.arrow_back_ios_new_rounded,
        size: 17,
        color: ColorPalette.textPrimary,
      ),
    ),
  );
}

// ── Contact row ───────────────────────────────────────────────────────────────
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ContactRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFFECF0FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: ColorPalette.secondary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                color: ColorPalette.textSecondary,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
