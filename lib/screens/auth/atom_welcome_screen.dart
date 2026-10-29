import 'package:flutter/material.dart';

import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../widgets/atom_button.dart';

/// First launch (canvas: "Welcome"): create an account, sign in, or shop as
/// a guest.
class AtomWelcomeScreen extends StatelessWidget {
  const AtomWelcomeScreen({super.key});

  static const _benefits = ['Verified sellers deliver in your area', 'See the monthly amount before you order', 'Track every installment in the app'];

  @override
  Widget build(BuildContext context) {
    final gutter = context.atomGutter;
    return Scaffold(
      body: AtomPageWidth(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const _Hero(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(gutter, AtomSpace.xs, gutter, AtomSpace.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final b in _benefits)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(color: AtomColors.primarySoft, shape: BoxShape.circle),
                                  child: const Icon(Icons.check_rounded, size: 15, color: AtomColors.primary),
                                ),
                                const SizedBox(width: AtomSpace.sm),
                                Expanded(child: Text(b, style: AtomText.label.copyWith(fontWeight: FontWeight.w600))),
                              ],
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(color: AtomColors.surface, borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              const _AppPair(),
                              const SizedBox(width: 10),
                              Expanded(child: Text('One account for Atomshop and AtomPay', style: AtomText.small.copyWith(color: AtomColors.body))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(gutter, AtomSpace.xs, gutter, AtomSpace.sm),
                child: Column(
                  children: [
                    AtomButton(label: 'Create account', icon: Icons.person_add_alt_1_rounded, expand: true, onPressed: () => AtomNav.register(context, replace: true)),
                    const SizedBox(height: 10),
                    AtomButton(
                      label: 'Sign in',
                      icon: Icons.login_rounded,
                      expand: true,
                      variant: AtomButtonVariant.secondary,
                      onPressed: () => AtomNav.signIn(context, replace: true),
                    ),
                    const SizedBox(height: 4),
                    AtomButton(
                      label: 'Continue as guest',
                      icon: Icons.shopping_bag_outlined,
                      variant: AtomButtonVariant.text,
                      onPressed: () => AtomNav.finishAuth(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The design's photo hero: the seller and customer on the right, a white
/// fade on the left with the logo and the headline, fading into the page.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final gutter = context.atomGutter;
    return SizedBox(
      height: 380 + top,
      child: LayoutBuilder(
        builder: (context, c) => Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFFF3F4FA)),
            Image.asset(
              'assets/images/slide-pay-in-steps.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(0.48, -0.4),
              cacheWidth: (c.maxWidth * MediaQuery.devicePixelRatioOf(context)).round(),
              semanticLabel: 'A seller showing a customer an installment plan on a tablet',
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFAFFFFFF), Color(0xE0FFFFFF), Color(0x00FFFFFF)], stops: [0, 0.4, 0.66]),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 60,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00FFFFFF), AtomColors.white]),
                ),
              ),
            ),
            Positioned(
              left: gutter,
              top: top + 22,
              bottom: 40,
              width: c.maxWidth * 0.56,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/images/app-atomshop.png', width: 54, height: 54, semanticLabel: 'Atomshop'),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ATOMSHOP.PK', style: AtomText.eyebrow),
                      const SizedBox(height: AtomSpace.xs),
                      Semantics(header: true, child: Text('Buy now. Pay in steps.', style: AtomText.title.copyWith(fontSize: 28, height: 1.1, letterSpacing: -0.8))),
                      const SizedBox(height: AtomSpace.xs),
                      Text('Phones, ACs, bikes and more on easy monthly installments.', style: AtomText.body),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Atomshop and AtomPay marks, overlapping.
class _AppPair extends StatelessWidget {
  const _AppPair();

  @override
  Widget build(BuildContext context) {
    Widget mark(String asset, {double pad = 0}) => Container(
          width: 30,
          height: 30,
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(color: AtomColors.white, shape: BoxShape.circle, border: Border.all(color: AtomColors.white, width: 2)),
          child: ClipOval(child: Image.asset(asset, fit: BoxFit.contain, excludeFromSemantics: true)),
        );
    return SizedBox(
      width: 52,
      height: 30,
      child: Stack(
        children: [
          mark('assets/images/app-atomshop.png'),
          Positioned(left: 22, child: mark('assets/images/app-atompay.png', pad: 3)),
        ],
      ),
    );
  }
}
