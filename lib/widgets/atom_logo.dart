import 'package:flutter/material.dart';

/// The Atomshop.pk logo: the round mark beside the "ATOMSHOP.PK · PAY IN
/// STEPS" wordmark. Both are cropped tight from the website's nav logo so
/// the name stays readable at header size (the full image has wide margins
/// and shrinks the text to a few pixels). Scales down on narrow screens.
class AtomLogo extends StatelessWidget {
  const AtomLogo({super.key, this.height = 40});

  /// Height of the mark; the wordmark is 70% of it.
  final double height;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final wordHeight = height * 0.7;
    return Semantics(
      label: 'Atomshop.pk, pay in steps',
      image: true,
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo-mark.png', height: height, cacheHeight: (height * dpr).round()),
            SizedBox(width: height * 0.2),
            Image.asset('assets/images/logo-wordmark.png', height: wordHeight, cacheHeight: (wordHeight * dpr).round()),
          ],
        ),
      ),
    );
  }
}
