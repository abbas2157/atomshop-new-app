import 'package:atompro/core/style/app_text_styles.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class CustomButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final IconData? suffixIcon;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final BorderSide? borderSide;
  final double? iconSize;
  final bool isOutlined;

  const CustomButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
    this.height,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 8.0,
    this.borderSide,
    this.iconSize = 20.0,
    this.isOutlined = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the active state
    final bool isInactive = isDisabled || isLoading || onPressed == null;

    // Colors based on button type
    final Color bgColor = isOutlined
        ? Colors.transparent
        : (backgroundColor ?? ColorPalette.secondary);
    final Color txtColor = isOutlined
        ? (textColor ?? ColorPalette.secondary)
        : (textColor ?? Colors.white);

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? context.h(55),
      child: ElevatedButton(
        onPressed: isInactive ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: txtColor,
          elevation: isOutlined ? 0 : 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side:
                borderSide ??
                (isOutlined
                    ? BorderSide(
                        color: backgroundColor ?? ColorPalette.secondary,
                        width: 2,
                      )
                    : BorderSide.none),
          ),
          // State-based coloring
          disabledBackgroundColor: isOutlined
              ? Colors.transparent
              : ColorPalette.border,
          disabledForegroundColor: ColorPalette.textSecondary,
        ),
        child: isLoading ? _buildLoader(txtColor) : _buildContent(txtColor),
      ),
    );
  }

  Widget _buildContent(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: iconSize),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: AppTextStyles.buttonMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (suffixIcon != null) ...[
          const SizedBox(width: 8),
          Icon(icon, size: iconSize, color: color),
        ],
      ],
    );
  }

  Widget _buildLoader(Color color) {
    return SizedBox(
      height: 24,
      width: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

// Secondary Button variant (Yellow Primary)
class PrimaryButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      title: title,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      width: width,
      backgroundColor: ColorPalette.primary,
      textColor: ColorPalette.textPrimary,
    );
  }
}

// Outlined Button variant
class OutlinedCustomButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final Color? borderColor;

  const OutlinedCustomButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      title: title,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      width: width,
      isOutlined: true,
      backgroundColor: borderColor,
      textColor: borderColor,
    );
  }
}
