import 'package:flutter/material.dart';

/// A safe scroll wrapper that prevents RenderFlex overflow in long Columns.
/// Use this around forms, onboarding screens, OTP screens, and any tall content
/// that may overflow on small devices.
///
/// Example:
/// ```dart
/// SafeScrollWrapper(
///   child: Column(
///     mainAxisSize: MainAxisSize.min,
///     children: [...],
///   ),
/// )
/// ```
class SafeScrollWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const SafeScrollWrapper({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: padding,
      child: child,
    );
  }
}
