import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:atompro/core/style/color_palette.dart';

class ReturnRefundPolicy extends StatelessWidget {
  const ReturnRefundPolicy({super.key});

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
                          const Expanded(
                            child: Text(
                              'Return & Refund Policy',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: ColorPalette.textPrimary,
                                letterSpacing: -0.5,
                              ),
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
                                Icons.assignment_return_outlined,
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
                                    'AtomShop.pk',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Please review our return and refund conditions carefully before making a purchase.',
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
                  // Return Policy section
                  _label('Return Policy'),
                  const SizedBox(height: 10),
                  _card(
                    child: Column(
                      children: [
                        _policyTile(
                          icon: Icons.swap_horiz_rounded,
                          text:
                              'Returns are accepted only if you receive the wrong item or a non-functional product at the time of delivery.',
                        ),
                        _divider(),
                        _policyTile(
                          icon: Icons.inventory_2_outlined,
                          text:
                              'Items must be unused, unscratched, and in original packaging with an invoice for return requests.',
                        ),
                        _divider(),
                        _policyTile(
                          icon: Icons.local_shipping_outlined,
                          text:
                              'Check your item at delivery; claims after that will not be entertained.',
                        ),
                        _divider(),
                        _policyTile(
                          icon: Icons.access_time_rounded,
                          text:
                              'Certain products (ACs, UPS, Burners, etc.) must be checked within 5 working days for any complaints.',
                        ),
                        _divider(),
                        _policyTile(
                          icon: Icons.build_outlined,
                          text:
                              'If a product is defective after delivery, claim through the manufacturer\'s warranty.',
                        ),
                        _divider(),
                        _policyTile(
                          icon: Icons.account_balance_wallet_outlined,
                          text:
                              'Refunds, if approved, are processed within 7–10 business days; shipping costs are non-refundable.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // No Exchanges & Cancellations
                  _label('No Exchanges & Cancellations'),
                  const SizedBox(height: 10),
                  _card(
                    child: Column(
                      children: [
                        _policyTile(
                          icon: Icons.block_rounded,
                          iconColor: ColorPalette.error,
                          text:
                              'No replacements or exchanges; check items at delivery.',
                        ),
                        _divider(),
                        _policyTile(
                          icon: Icons.cancel_outlined,
                          iconColor: ColorPalette.error,
                          text: 'Orders can be canceled before shipment only.',
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
                            'By placing an order on AtomShop.pk, you agree to this Return & Refund Policy.',
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

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
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

  Widget _policyTile({
    required IconData icon,
    required String text,
    Color iconColor = ColorPalette.secondary,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: ColorPalette.textSecondary,
                  height: 1.55,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, indent: 66, color: ColorPalette.border);

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
