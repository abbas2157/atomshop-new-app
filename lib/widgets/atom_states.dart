import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../data/atom_errors.dart';
import '../design/atom_text.dart';
import '../design/atom_tokens.dart';
import 'atom_button.dart';

/// Grey block that shimmers while content loads. Compose it into skeletons
/// shaped like the real content so the layout does not jump.
class AtomSkeleton extends StatelessWidget {
  const AtomSkeleton({super.key, this.width, this.height = 16, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AtomColors.surface,
      highlightColor: AtomColors.white,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: AtomColors.surface, borderRadius: BorderRadius.circular(radius)),
      ),
    );
  }
}

/// Empty state: says what is missing and offers the next action (DESIGN.md §1.9).
class AtomEmptyState extends StatelessWidget {
  const AtomEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AtomSpace.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: AtomColors.primarySoft, borderRadius: BorderRadius.circular(22)),
            child: Icon(icon, size: 34, color: AtomColors.primary),
          ),
          const SizedBox(height: AtomSpace.sm),
          Text(title, style: AtomText.heading, textAlign: TextAlign.center),
          const SizedBox(height: AtomSpace.xxs),
          Text(message, style: AtomText.body, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AtomSpace.md),
            AtomButton(label: actionLabel!, icon: actionIcon ?? Icons.arrow_forward_rounded, onPressed: onAction, size: AtomButtonSize.medium),
          ],
        ],
      ),
    );
  }
}

/// Error with a retry button. Pass the [error] so the screen says what went
/// wrong (offline, slow, server trouble, not found) instead of guessing.
class AtomErrorState extends StatelessWidget {
  const AtomErrorState({super.key, required this.onRetry, this.message, this.error});

  final VoidCallback onRetry;
  final String? message;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final info = atomLoadError(error);
    return AtomEmptyState(
      icon: info.icon,
      title: info.title,
      message: message ?? info.message,
      actionLabel: 'Try again',
      actionIcon: Icons.refresh_rounded,
      onAction: onRetry,
    );
  }
}

/// Renders an [AsyncValue] with one consistent loading, error and data
/// treatment. While refreshing it keeps showing the previous data instead of
/// flashing the skeleton (Riverpod keeps `value` during reloads).
class AtomAsync<T> extends StatelessWidget {
  const AtomAsync({
    super.key,
    required this.value,
    required this.data,
    required this.loading,
    required this.onRetry,
    this.compactError = false,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget loading;
  final VoidCallback onRetry;

  /// Small inline retry row for sections inside a page (e.g. one home row).
  final bool compactError;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      data: data,
      loading: () => loading,
      error: (error, _) => compactError ? _InlineRetry(onRetry: onRetry, error: error) : AtomErrorState(onRetry: onRetry, error: error),
    );
  }
}

class _InlineRetry extends StatelessWidget {
  const _InlineRetry({required this.onRetry, this.error});

  final VoidCallback onRetry;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline_rounded, size: 18, color: AtomColors.muted),
        const SizedBox(width: AtomSpace.xs),
        Expanded(child: Text(atomLoadError(error).message, style: AtomText.body.copyWith(fontSize: 13))),
        AtomButton(label: 'Retry', icon: Icons.refresh_rounded, onPressed: onRetry, size: AtomButtonSize.small, variant: AtomButtonVariant.secondary),
      ],
    );
  }
}
