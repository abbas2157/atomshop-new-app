import 'package:flutter/material.dart';

import '../design/atom_tokens.dart';

/// Draws a 2 px ring just outside [shape] while the control inside has
/// keyboard focus. The builder gets the callback to hand to the control's
/// `InkWell.onFocusChange`. The ring sits outside the bounds, so focusing
/// never moves the layout.
class AtomFocusRing extends StatefulWidget {
  const AtomFocusRing({super.key, required this.shape, required this.builder, this.color = AtomColors.primary});

  final OutlinedBorder shape;
  final Color color;
  final Widget Function(BuildContext context, ValueChanged<bool> onFocusChange) builder;

  @override
  State<AtomFocusRing> createState() => _AtomFocusRingState();
}

class _AtomFocusRingState extends State<AtomFocusRing> {
  bool _focused = false;

  void _onFocusChange(bool focused) {
    if (focused != _focused) setState(() => _focused = focused);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: _focused
          ? ShapeDecoration(shape: widget.shape.copyWith(side: BorderSide(color: widget.color, width: 2, strokeAlign: BorderSide.strokeAlignOutside)))
          : const BoxDecoration(),
      child: widget.builder(context, _onFocusChange),
    );
  }
}
