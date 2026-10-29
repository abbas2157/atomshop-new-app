import 'package:flutter/material.dart';

import '../design/atom_text.dart';
import '../design/atom_tokens.dart';
import '../responsive/atom_responsive.dart';
import 'atom_button.dart';

/// Full-width photo header from the design (About us, Make an offer): the
/// people stay on the right, a white fade on the left carries the eyebrow
/// and title, and a round back button sits on top.
class AtomPhotoHero extends StatelessWidget {
  const AtomPhotoHero({
    super.key,
    required this.asset,
    required this.alt,
    required this.eyebrow,
    required this.title,
    this.height = 240,
    this.alignment = const Alignment(0.44, -0.2),
    this.textWidthFactor = 0.54,
  });

  final String asset;
  final String alt;
  final String eyebrow;
  final String title;
  final double height;
  final Alignment alignment;
  final double textWidthFactor;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final gutter = context.atomGutter;
    return SizedBox(
      height: height + top,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFF3F4FA), border: Border(bottom: BorderSide(color: AtomColors.line))),
        child: LayoutBuilder(
          builder: (context, c) => Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(asset, fit: BoxFit.cover, alignment: alignment, cacheWidth: (c.maxWidth * MediaQuery.devicePixelRatioOf(context)).round(), semanticLabel: alt),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xF7FFFFFF), Color(0xDBFFFFFF), Color(0x00FFFFFF)], stops: [0, 0.42, 0.64]),
                ),
              ),
              if (Navigator.of(context).canPop())
                Positioned(
                  top: top + 14,
                  left: gutter,
                  child: AtomIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onPressed: () => Navigator.of(context).maybePop()),
                ),
              Positioned(
                left: gutter,
                bottom: 22,
                width: c.maxWidth * textWidthFactor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(eyebrow.toUpperCase(), style: AtomText.eyebrow),
                    const SizedBox(height: 6),
                    Semantics(header: true, child: Text(title, style: AtomText.title.copyWith(fontSize: 22, height: 1.15))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
