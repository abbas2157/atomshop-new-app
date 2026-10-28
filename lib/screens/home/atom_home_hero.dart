import 'package:flutter/material.dart';

import '../../data/atom_design_content.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../widgets/atom_button.dart';

/// Home banner carousel with the design's slides ([designSlides]): the photo
/// keeps the people on the right, the text sits on a white fade on the left.
///
/// Memory: one PageController, disposed with the widget; photos decode at
/// the banner's width, and PageView builds only the visible page and its
/// neighbours.
class AtomHomeHero extends StatefulWidget {
  const AtomHomeHero({super.key, required this.slides, required this.onAction});

  final List<DesignSlide> slides;
  final ValueChanged<SlideAction> onAction;

  @override
  State<AtomHomeHero> createState() => _AtomHomeHeroState();
}

class _AtomHomeHeroState extends State<AtomHomeHero> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = widget.slides;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AtomRadius.hero),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4FA),
          border: Border.all(color: AtomColors.line),
          borderRadius: BorderRadius.circular(AtomRadius.hero),
        ),
        child: SizedBox(
          height: 220 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.15),
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _Slide(slide: slides[i], onAction: widget.onAction),
              ),
              if (slides.length > 1)
                Positioned(
                  left: 18,
                  bottom: 6,
                  child: Row(
                    children: [
                      for (var i = 0; i < slides.length; i++)
                        Semantics(
                          button: true,
                          label: 'Show slide ${i + 1}',
                          selected: i == _page,
                          child: GestureDetector(
                            onTap: () => _controller.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: i == _page ? 22 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: i == _page ? AtomColors.primary : AtomColors.line2,
                                  borderRadius: BorderRadius.circular(AtomRadius.pill),
                                ),
                              ),
                            ),
                          ),
                        ),
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

class _Slide extends StatelessWidget {
  const _Slide({required this.slide, required this.onAction});

  final DesignSlide slide;
  final ValueChanged<SlideAction> onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final decodeWidth = (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context)).round();
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(slide.asset, fit: BoxFit.cover, alignment: slide.alignment, cacheWidth: decodeWidth, semanticLabel: slide.alt),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xF7FFFFFF), Color(0xE6FFFFFF), Color(0x00FFFFFF)], stops: [0, 0.38, 0.62]),
              ),
            ),
            FractionallySizedBox(
              widthFactor: 0.58,
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 0, 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(slide.eyebrow.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.eyebrow.copyWith(fontSize: 11)),
                    const SizedBox(height: 8),
                    Flexible(
                      child: Text(
                        slide.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AtomText.heading.copyWith(fontSize: 19, height: 1.15, letterSpacing: -0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AtomButton(label: slide.cta, icon: slide.icon, onPressed: () => onAction(slide.action), size: AtomButtonSize.small),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
