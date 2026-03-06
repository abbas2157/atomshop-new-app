import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// Padding Extensions
/// Makes padding super easy with responsive sizes
extension PaddingExtensions on Widget {
  // All sides padding
  Widget paddingAll(double value) {
    return Padding(padding: EdgeInsets.all(value.w), child: this);
  }

  // Symmetric padding
  Widget paddingSymmetric({double horizontal = 0, double vertical = 0}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal.w,
        vertical: vertical.h,
      ),
      child: this,
    );
  }

  // Individual sides padding
  Widget paddingOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: left.w,
        top: top.h,
        right: right.w,
        bottom: bottom.h,
      ),
      child: this,
    );
  }

  // Horizontal padding
  Widget paddingHorizontal(double value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: value.w),
      child: this,
    );
  }

  // Vertical padding
  Widget paddingVertical(double value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: value.h),
      child: this,
    );
  }

  // Individual directional padding
  Widget paddingLeft(double value) {
    return Padding(
      padding: EdgeInsets.only(left: value.w),
      child: this,
    );
  }

  Widget paddingRight(double value) {
    return Padding(
      padding: EdgeInsets.only(right: value.w),
      child: this,
    );
  }

  Widget paddingTop(double value) {
    return Padding(
      padding: EdgeInsets.only(top: value.h),
      child: this,
    );
  }

  Widget paddingBottom(double value) {
    return Padding(
      padding: EdgeInsets.only(bottom: value.h),
      child: this,
    );
  }

  // Predefined padding sizes
  Widget get paddingTiny => paddingAll(4);
  Widget get paddingSmall => paddingAll(8);
  Widget get paddingMedium => paddingAll(16);
  Widget get paddingLarge => paddingAll(24);
  Widget get paddingXLarge => paddingAll(32);
  Widget get paddingXXLarge => paddingAll(40);
}

/// Margin Extensions
/// Same as padding but using Container with margin
extension MarginExtensions on Widget {
  // All sides margin
  Widget marginAll(double value) {
    return Container(margin: EdgeInsets.all(value.w), child: this);
  }

  // Symmetric margin
  Widget marginSymmetric({double horizontal = 0, double vertical = 0}) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: horizontal.w,
        vertical: vertical.h,
      ),
      child: this,
    );
  }

  // Individual sides margin
  Widget marginOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return Container(
      margin: EdgeInsets.only(
        left: left.w,
        top: top.h,
        right: right.w,
        bottom: bottom.h,
      ),
      child: this,
    );
  }

  // Horizontal margin
  Widget marginHorizontal(double value) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: value.w),
      child: this,
    );
  }

  // Vertical margin
  Widget marginVertical(double value) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: value.h),
      child: this,
    );
  }

  // Individual directional margin
  Widget marginLeft(double value) {
    return Container(
      margin: EdgeInsets.only(left: value.w),
      child: this,
    );
  }

  Widget marginRight(double value) {
    return Container(
      margin: EdgeInsets.only(right: value.w),
      child: this,
    );
  }

  Widget marginTop(double value) {
    return Container(
      margin: EdgeInsets.only(top: value.h),
      child: this,
    );
  }

  Widget marginBottom(double value) {
    return Container(
      margin: EdgeInsets.only(bottom: value.h),
      child: this,
    );
  }

  // Predefined margin sizes
  Widget get marginTiny => marginAll(4);
  Widget get marginSmall => marginAll(8);
  Widget get marginMedium => marginAll(16);
  Widget get marginLarge => marginAll(24);
  Widget get marginXLarge => marginAll(32);
  Widget get marginXXLarge => marginAll(40);
}

/// Alignment Extensions
/// Quickly align widgets
extension AlignmentExtensions on Widget {
  // Basic alignments
  Widget get alignCenter => Align(alignment: Alignment.center, child: this);

  Widget get alignCenterLeft =>
      Align(alignment: Alignment.centerLeft, child: this);

  Widget get alignCenterRight =>
      Align(alignment: Alignment.centerRight, child: this);

  Widget get alignTopCenter =>
      Align(alignment: Alignment.topCenter, child: this);

  Widget get alignTopLeft => Align(alignment: Alignment.topLeft, child: this);

  Widget get alignTopRight => Align(alignment: Alignment.topRight, child: this);

  Widget get alignBottomCenter =>
      Align(alignment: Alignment.bottomCenter, child: this);

  Widget get alignBottomLeft =>
      Align(alignment: Alignment.bottomLeft, child: this);

  Widget get alignBottomRight =>
      Align(alignment: Alignment.bottomRight, child: this);

  // Custom alignment
  Widget align(Alignment alignment) {
    return Align(alignment: alignment, child: this);
  }
}

/// Center Extensions
extension CenterExtensions on Widget {
  Widget get center => Center(child: this);
}

/// Flexible & Expanded Extensions
extension FlexExtensions on Widget {
  Widget get expanded => Expanded(child: this);

  Widget flexible({int flex = 1, FlexFit fit = FlexFit.loose}) {
    return Flexible(flex: flex, fit: fit, child: this);
  }

  Widget expand(int flex) => Expanded(flex: flex, child: this);
}

/// Visibility Extensions
extension VisibilityExtensions on Widget {
  Widget visible(bool isVisible, {Widget? replacement}) {
    return Visibility(
      visible: isVisible,
      replacement: replacement ?? const SizedBox.shrink(),
      child: this,
    );
  }

  Widget hide(bool hide) {
    return Visibility(visible: !hide, child: this);
  }
}

/// Opacity Extensions
extension OpacityExtensions on Widget {
  Widget opacity(double opacity) {
    return Opacity(opacity: opacity, child: this);
  }

  Widget get transparent => opacity(0);
  Widget get semiTransparent => opacity(0.5);
}

/// Gesture Extensions
extension GestureExtensions on Widget {
  Widget onTap(VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: this);
  }

  Widget onLongPress(VoidCallback onLongPress) {
    return GestureDetector(onLongPress: onLongPress, child: this);
  }

  Widget onDoubleTap(VoidCallback onDoubleTap) {
    return GestureDetector(onDoubleTap: onDoubleTap, child: this);
  }
}

/// Container Extensions
extension ContainerExtensions on Widget {
  Widget container({
    double? width,
    double? height,
    Color? color,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Decoration? decoration,
    AlignmentGeometry? alignment,
  }) {
    return Container(
      width: width?.w,
      height: height?.h,
      color: color,
      padding: padding,
      margin: margin,
      decoration: decoration,
      alignment: alignment,
      child: this,
    );
  }

  // Quick container with color
  Widget withColor(Color color) {
    return Container(color: color, child: this);
  }

  // Quick container with size
  Widget withSize({double? width, double? height}) {
    return Container(width: width?.w, height: height?.h, child: this);
  }
}

/// Card Extensions
extension CardExtensions on Widget {
  Widget card({
    Color? color,
    double? elevation,
    ShapeBorder? shape,
    EdgeInsetsGeometry? margin,
  }) {
    return Card(
      color: color,
      elevation: elevation,
      shape: shape,
      margin: margin,
      child: this,
    );
  }

  Widget get cardDefault => Card(child: this);
}

/// Positioned Extensions
extension PositionedExtensions on Widget {
  Widget positioned({
    double? left,
    double? top,
    double? right,
    double? bottom,
    double? width,
    double? height,
  }) {
    return Positioned(
      left: left?.w,
      top: top?.h,
      right: right?.w,
      bottom: bottom?.h,
      width: width?.w,
      height: height?.h,
      child: this,
    );
  }

  Widget get positionedFill => Positioned.fill(child: this);
}

/// Scroll Extensions
extension ScrollExtensions on Widget {
  Widget get scrollable => SingleChildScrollView(child: this);

  Widget scrollVertical({ScrollController? controller}) {
    return SingleChildScrollView(controller: controller, child: this);
  }

  Widget scrollHorizontal({ScrollController? controller}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: controller,
      child: this,
    );
  }
}

/// Safe Area Extensions
extension SafeAreaExtensions on Widget {
  Widget get safeArea => SafeArea(child: this);

  Widget safeAreaCustom({
    bool top = true,
    bool bottom = true,
    bool left = true,
    bool right = true,
  }) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: this,
    );
  }
}

/// Hero Extensions
extension HeroExtensions on Widget {
  Widget hero(String tag) {
    return Hero(tag: tag, child: this);
  }
}

/// ClipRRect Extensions
extension ClipExtensions on Widget {
  Widget clipRRect(double radius) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius.r),
      child: this,
    );
  }

  Widget get clipCircle => ClipOval(child: this);

  Widget clipRRectCustom(BorderRadius borderRadius) {
    return ClipRRect(borderRadius: borderRadius, child: this);
  }
}

/// Transform Extensions
extension TransformExtensions on Widget {
  Widget rotate(double angle) {
    return Transform.rotate(angle: angle, child: this);
  }

  Widget scale(double scale) {
    return Transform.scale(scale: scale, child: this);
  }

  Widget translate({double x = 0, double y = 0}) {
    return Transform.translate(offset: Offset(x, y), child: this);
  }
}

/// SizedBox Extensions
extension SizedBoxExtensions on num {
  Widget get verticalSpace => SizedBox(height: toDouble().h);
  Widget get horizontalSpace => SizedBox(width: toDouble().w);
}

/// Decoration Extensions
extension DecorationExtensions on Widget {
  Widget decorated({
    Color? color,
    double? borderRadius,
    Border? border,
    List<BoxShadow>? boxShadow,
    Gradient? gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius != null
            ? BorderRadius.circular(borderRadius.r)
            : null,
        border: border,
        boxShadow: boxShadow,
        gradient: gradient,
      ),
      child: this,
    );
  }

  Widget roundedBorder({
    required double radius,
    Color? color,
    double borderWidth = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius.r),
        border: Border.all(color: color ?? Colors.grey, width: borderWidth),
      ),
      child: this,
    );
  }

  Widget withShadow({
    Color shadowColor = Colors.black,
    double blurRadius = 10,
    Offset offset = const Offset(0, 4),
    double opacity = 0.1,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(opacity),
            blurRadius: blurRadius,
            offset: offset,
          ),
        ],
      ),
      child: this,
    );
  }
}

/// InkWell Extensions
extension InkWellExtensions on Widget {
  Widget inkWell({required VoidCallback onTap, BorderRadius? borderRadius}) {
    return InkWell(onTap: onTap, borderRadius: borderRadius, child: this);
  }
}

/// Shimmer/Loading Extensions (for future use)
extension LoadingExtensions on Widget {
  Widget conditional(bool condition, Widget Function(Widget) builder) {
    return condition ? builder(this) : this;
  }
}
