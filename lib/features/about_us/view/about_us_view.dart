import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:atompro/core/style/color_palette.dart';

class AboutUs extends StatelessWidget {
  const AboutUs({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F5FB),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button + title row
                      Row(
                        children: [
                          GestureDetector(
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
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            'About Us',
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

                      // Brand card
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                              child: const Center(
                                child: Text(
                                  'A',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'AtomShop.pk',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Where affordability meets opportunity.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Stat chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people_outline_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    '50,000+ Satisfied Customers',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
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

            // ── Content ─────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Intro paragraphs
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _body(
                          'At AtomShop.pk, we make essential products affordable and accessible through flexible installment plans. No one should have to delay their needs due to financial barriers—that\'s why we provide easy payment options for appliances, electronics, and more.',
                        ),
                        const SizedBox(height: 12),
                        _body(
                          'But we go beyond just selling products—we empower individuals through AtomShop SAAS, offering training and digital tools to help aspiring entrepreneurs start their own businesses and earn a sustainable income.',
                        ),
                        const SizedBox(height: 12),
                        _body(
                          'AtomShop.pk isn\'t just a marketplace—it\'s a platform for financial freedom and opportunity.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Vision
                  _infoCard(
                    icon: Icons.visibility_outlined,
                    label: 'Our Vision',
                    text:
                        'To create a future where every Pakistani household has access to essential products, and aspiring entrepreneurs have the tools to succeed.',
                  ),
                  const SizedBox(height: 12),

                  // Mission
                  _infoCard(
                    icon: Icons.flag_outlined,
                    label: 'Our Mission',
                    text:
                        'To make products financially accessible while empowering individuals through business training and digital selling tools.',
                  ),
                  const SizedBox(height: 16),

                  // What We Offer
                  _label('What We Offer'),
                  const SizedBox(height: 10),
                  _card(
                    child: Column(
                      children: [
                        _offerTile(
                          Icons.verified_outlined,
                          'High-Quality Products',
                        ),
                        _divider(),
                        _offerTile(
                          Icons.calendar_month_outlined,
                          'Easy Monthly Installments',
                        ),
                        _divider(),
                        _offerTile(
                          Icons.support_agent_outlined,
                          '24/7 Online Support',
                        ),
                        _divider(),
                        _offerTile(
                          Icons.store_outlined,
                          'Business Opportunities with AtomShop SAAS',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // What We Do
                  _infoCard(
                    icon: Icons.bolt_outlined,
                    label: 'What We Do',
                    text:
                        'We offer flexible installment plans to make everyday essentials affordable. We also help entrepreneurs in Lahore start their businesses through AtomShop SAAS, enabling them to sell products, earn income, and uplift their communities.',
                  ),
                  const SizedBox(height: 12),

                  // History
                  _infoCard(
                    icon: Icons.history_edu_outlined,
                    label: 'Our History',
                    text:
                        'With 50,000+ satisfied customers, we understand the needs of the people we serve. Our mission is to continue breaking financial barriers and creating economic opportunities for all.',
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _label(String text) => Padding(
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

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String text,
  }) {
    return Container(
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
            child: Icon(icon, size: 20, color: ColorPalette.secondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: ColorPalette.textPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: ColorPalette.textSecondary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _offerTile(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFECF0FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: ColorPalette.secondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ColorPalette.textPrimary,
              ),
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: Color(0xFF3CAC10),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: ColorPalette.border);

  Widget _body(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13.5,
      color: ColorPalette.textSecondary,
      height: 1.6,
    ),
  );
}
