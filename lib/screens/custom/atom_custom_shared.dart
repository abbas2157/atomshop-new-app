import 'package:flutter/material.dart';

import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';

/// What the customer typed on step 1 of a custom order. The figures for it
/// always come from the server's quote.
class CustomDraft {
  const CustomDraft({required this.title, required this.price, required this.advance, required this.months, required this.referenceCode});

  final String title;
  final int price;
  final int advance;
  final int months;
  final String referenceCode;
}

/// 1 Calculator · 2 Plan review · 3 Your details.
class CustomSteps extends StatelessWidget {
  const CustomSteps({super.key, required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    Widget step(int n, String label) {
      final done = n < current;
      final on = n == current;
      final color = done ? AtomColors.green : (on ? AtomColors.primary : AtomColors.muted);
      return Expanded(
        child: Semantics(
          label: '$label${done ? ', done' : on ? ', current step' : ''}',
          excludeSemantics: true,
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: done || on ? color : null,
                  shape: BoxShape.circle,
                  border: done || on ? null : Border.all(color: AtomColors.line2, width: 1.5),
                ),
                child: done
                    ? const Icon(Icons.check_rounded, size: 13, color: AtomColors.white)
                    : Text('$n', style: AtomText.small.copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: on ? AtomColors.white : AtomColors.muted)),
              ),
              const SizedBox(width: 6),
              Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.small.copyWith(color: color, fontWeight: FontWeight.w700))),
            ],
          ),
        ),
      );
    }

    return Row(children: [step(1, 'Calculator'), step(2, 'Plan review'), step(3, 'Your details')]);
  }
}
