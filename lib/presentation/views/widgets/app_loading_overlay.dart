import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Reusable animated custom spinner styled to match Subscart's clean aesthetic.
class AppCustomSpinner extends StatefulWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const AppCustomSpinner({
    super.key,
    this.size = 28,
    this.color,
    this.strokeWidth = 3.0,
  });

  @override
  State<AppCustomSpinner> createState() => _AppCustomSpinnerState();
}

class _AppCustomSpinnerState extends State<AppCustomSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.color ?? AppColors.primaryDark;

    return RotationTransition(
      turns: _controller,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _CustomSpinnerPainter(
            color: primaryColor,
            strokeWidth: widget.strokeWidth,
          ),
        ),
      ),
    );
  }
}

class _CustomSpinnerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _CustomSpinnerPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track circle (very light accent)
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Active rotating sweep arc
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // Start from top (-90 degrees)
      4.2,     // Sweep ~240 degrees
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CustomSpinnerPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Reusable full-page or inline loader with title and message.
class AppInlineLoader extends StatelessWidget {
  final String? message;

  const AppInlineLoader({
    super.key,
    this.message = 'Loading subscription plan...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F111827),
                  blurRadius: 18,
                  offset: Offset(0, 4),
                ),
              ],
              border: Border.all(color: AppColors.subtleBorder),
            ),
            child: const AppCustomSpinner(size: 32, strokeWidth: 3.2),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: AppTextStyles.screenSubtitle.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Reusable modal loading overlay that visually indicates an in-flight API request
/// and completely absorbs all touch events to block duplicate user interactions.
class AppLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String? message;
  final Widget child;

  const AppLoadingOverlay({
    super.key,
    required this.isLoading,
    this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.25),
                  alignment: Alignment.center,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 200),
                    tween: Tween<double>(begin: 0.85, end: 1.0),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 22,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.subtleBorder),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x2E111827),
                            blurRadius: 28,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppCustomSpinner(
                            size: 36,
                            strokeWidth: 3.5,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            message ?? 'Please wait...',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.cardHeader.copyWith(
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Processing your request',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.helperText,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
