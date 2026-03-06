import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:atompro/core/style/color_palette.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
                            'Privacy Policy',
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
                                Icons.privacy_tip_outlined,
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
                                    'Your Privacy Matters',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'AtomShop.pk is committed to protecting your personal data and being transparent about how we use it.',
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
                  // Intro
                  _card(
                    child: _body(
                      'AtomShop.pk is an online marketplace facilitating installment-based purchases. By using this website, you agree to abide by the terms and conditions outlined below. If you disagree, please refrain from using the platform.',
                    ),
                  ),
                  const SizedBox(height: 16),

                  _section(
                    number: '1',
                    title: 'Acceptance of Terms',
                    bullets: null,
                    text:
                        'By accessing AtomShop.pk, you acknowledge that this platform enables users to place orders for products on installments. This process requires verification and approval before fulfillment. The terms may change without prior notice, and continued use signifies acceptance.',
                  ),
                  const SizedBox(height: 12),

                  _section(
                    number: '2',
                    title: 'Order Placement & Verification',
                    text: null,
                    bullets: [
                      'Customers must provide accurate information when placing an order.',
                      'Sellers on AtomShop.pk reserve the right to cancel any order after verification.',
                      'If an order is rejected, the customer is responsible for collecting all submitted documents.',
                      'One product can be purchased per CNIC at a time, subject to approval.',
                      'Post-dated cheques may be required in some cases.',
                    ],
                  ),
                  const SizedBox(height: 12),

                  _section(
                    number: '3',
                    title: 'Eligibility',
                    text: null,
                    bullets: [
                      'Users must be at least 18 years old and legally able to enter contracts in Pakistan.',
                      'Providing false or inaccurate information may lead to account termination.',
                    ],
                  ),
                  const SizedBox(height: 12),

                  _section(
                    number: '4',
                    title: 'Account Security',
                    text: null,
                    bullets: [
                      'Users are responsible for maintaining the confidentiality of their accounts.',
                      'Any unauthorized access should be reported immediately.',
                      'AtomShop.pk is not liable for any loss resulting from account misuse.',
                    ],
                  ),
                  const SizedBox(height: 12),

                  _section(
                    number: '5',
                    title: 'Product Delivery & Warranty',
                    text: null,
                    bullets: [
                      'Delivery is subject to vendor timelines and market conditions.',
                      'Customers must sign a delivery note acknowledging receipt.',
                      'Warranty claims must be made directly to the manufacturer or authorized service centers.',
                      'AtomShop.pk does not provide insurance for any purchased items.',
                    ],
                  ),
                  const SizedBox(height: 12),

                  _section(
                    number: '6',
                    title: 'Pricing & Availability',
                    text: null,
                    bullets: [
                      'Prices and availability are subject to change without notice.',
                      'Once an order is locked, the agreed amount will not fluctuate based on market changes.',
                    ],
                  ),
                  const SizedBox(height: 12),

                  _section(
                    number: '7',
                    title: 'Cancellations & Refunds',
                    text: null,
                    bullets: [
                      'Sellers may cancel orders at their discretion after verification.',
                      'Customers must collect their documents upon order rejection.',
                      'Overpayments may be adjusted in future installments or refunded within 45 days upon request.',
                    ],
                  ),
                  const SizedBox(height: 12),

                  _section(
                    number: '8',
                    title: 'Privacy & Data Security',
                    text: null,
                    bullets: [
                      'Customer data is securely stored and accessed on a need-to-know basis.',
                      'Data may be shared with third-party verification agencies as required.',
                      'AtomShop.pk will not access personal mobile data.',
                    ],
                  ),
                  const SizedBox(height: 12),

                  _section(
                    number: '9',
                    title: 'Legal Compliance & Disputes',
                    text: null,
                    bullets: [
                      'Transactions are governed by the laws of Pakistan.',
                      'Any disputes will be resolved in Pakistani courts.',
                      'Users should conduct due diligence before entering any agreement.',
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Section 10 — Contact
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
                              '10',
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
                                'Customer Support & Grievances',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: ColorPalette.textPrimary,
                                ),
                              ),
                              SizedBox(height: 10),
                              _ContactRow(
                                icon: Icons.email_outlined,
                                label: 'support@atomshop.pk',
                              ),
                              SizedBox(height: 8),
                              _ContactRow(
                                icon: Icons.phone_outlined,
                                label: '0330-2277522',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Footer note
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
                            'By using AtomShop.pk, you acknowledge and agree to these terms.',
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

  // ── Section card ──────────────────────────────────────────────────────────
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
                if (bullets != null) ...bullets.map((b) => _bulletItem(b)),
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
            padding: const EdgeInsets.only(top: 6),
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

// ── Contact row ──────────────────────────────────────────────────────────────
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ContactRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            color: ColorPalette.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
