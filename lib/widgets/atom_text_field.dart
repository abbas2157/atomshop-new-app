import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

import '../design/atom_text.dart';
import '../design/atom_tokens.dart';

/// Labelled text field. The label sits above the field (never only a
/// placeholder), so it stays readable while typing and for screen readers.
///
/// The caller owns [controller] and must dispose it (a StatefulWidget or a
/// form notifier); this widget never creates controllers, so nothing leaks.
class AtomTextField extends StatelessWidget {
  const AtomTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.optional = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.inputFormatters,
    this.prefix,
    this.suffix,
    this.maxLines = 1,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final bool optional;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefix;
  final Widget? suffix;
  final int maxLines;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: AtomText.label,
            children: [if (optional) TextSpan(text: ' (optional)', style: AtomText.body.copyWith(fontSize: 13, color: AtomColors.muted))],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          maxLines: obscureText ? 1 : maxLines,
          autofillHints: autofillHints,
          textCapitalization: textCapitalization,
          style: AtomText.body.copyWith(fontSize: 15, color: AtomColors.ink),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefix,
            suffixIcon: suffix,
            semanticCounterText: label,
          ),
        ),
      ],
    );
  }
}

/// Pill search field (Shop, category and brand lists). Filters as you type;
/// the clear button shows once there is text. The caller owns [controller].
class AtomSearchField extends StatelessWidget {
  const AtomSearchField({super.key, required this.controller, required this.hint, this.onChanged, this.autofocus = false});

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(AtomRadius.pill), borderSide: const BorderSide(color: AtomColors.fieldLine));
    return TextField(
      controller: controller,
      onChanged: onChanged,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      style: AtomText.body.copyWith(fontSize: 15, color: AtomColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AtomColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AtomSpace.md, vertical: 13),
        prefixIcon: const Icon(Icons.search_rounded, color: AtomColors.body, size: 20),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close_rounded, size: 20, color: AtomColors.body),
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                ),
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: const BorderSide(color: AtomColors.primary, width: 1.5)),
      ),
    );
  }
}

/// Password field with a show/hide button. Owns no controller: the caller
/// passes and disposes it.
class AtomPasswordField extends StatefulWidget {
  const AtomPasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.hint,
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.newPassword = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;

  /// Lets password managers offer a new strong password.
  final bool newPassword;

  @override
  State<AtomPasswordField> createState() => _AtomPasswordFieldState();
}

class _AtomPasswordFieldState extends State<AtomPasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AtomText.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          obscureText: _hidden,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted == null ? null : (_) => widget.onSubmitted!(),
          autofillHints: [widget.newPassword ? AutofillHints.newPassword : AutofillHints.password],
          style: AtomText.body.copyWith(fontSize: 15, color: AtomColors.ink),
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixIcon: IconButton(
              tooltip: _hidden ? 'Show password' : 'Hide password',
              icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AtomColors.body),
              onPressed: () => setState(() => _hidden = !_hidden),
            ),
          ),
        ),
      ],
    );
  }
}

/// One-time code boxes (sign-up and forgot password). The server sends
/// 4-digit codes. The caller owns [controller].
class AtomCodeField extends StatelessWidget {
  const AtomCodeField({super.key, required this.controller, this.length = 4, this.onCompleted, this.errorText});

  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onCompleted;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final box = PinTheme(
      width: 62,
      height: 62,
      textStyle: AtomText.title.copyWith(fontSize: 24),
      decoration: BoxDecoration(
        color: AtomColors.white,
        borderRadius: BorderRadius.circular(AtomRadius.input),
        border: Border.all(color: AtomColors.fieldLine),
      ),
    );
    return Semantics(
      label: 'Enter the $length-digit code',
      child: Pinput(
        length: length,
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        forceErrorState: errorText != null,
        errorText: errorText,
        errorTextStyle: AtomText.small.copyWith(color: AtomColors.rose),
        onCompleted: onCompleted,
        defaultPinTheme: box,
        focusedPinTheme: box.copyDecorationWith(border: Border.all(color: AtomColors.primary, width: 1.5)),
        errorPinTheme: box.copyDecorationWith(border: Border.all(color: AtomColors.rose, width: 1.5)),
      ),
    );
  }
}
