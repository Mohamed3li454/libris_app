import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:libris_app/core/theme/app_theme.dart';

class WaterFillDownloadButton extends StatefulWidget {
  final String label;
  final double progress;
  final bool waving;
  final VoidCallback onPressed;

  const WaterFillDownloadButton({
    super.key,
    required this.label,
    required this.progress,
    required this.waving,
    required this.onPressed,
  });

  @override
  State<WaterFillDownloadButton> createState() =>
      _WaterFillDownloadButtonState();
}

class _WaterFillDownloadButtonState extends State<WaterFillDownloadButton>
    with TickerProviderStateMixin {
  late final AnimationController _wave;
  late final AnimationController _fillCtrl;
  late Animation<double> _fill;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _fillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final start = widget.progress.clamp(0.0, 1.0);
    _fill = AlwaysStoppedAnimation(start);
    if (widget.waving) {
      _wave.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant WaterFillDownloadButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.waving && !_wave.isAnimating) {
      _wave.repeat();
    } else if (!widget.waving && _wave.isAnimating) {
      _wave.stop();
    }

    final target = widget.progress.clamp(0.0, 1.0);
    final current = _fill.value;
    if ((target - current).abs() < 0.002) return;

    final distance = (target - current).abs();
    _fill = Tween<double>(begin: current, end: target).animate(
      CurvedAnimation(parent: _fillCtrl, curve: Curves.easeInOutCubic),
    );
    _fillCtrl
      ..duration = Duration(
        milliseconds: (700 + distance * 1100).round().clamp(700, 1600),
      )
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _wave.dispose();
    _fillCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waterColor = context.colors.primary;
    final emptyColor = waterColor.withValues(alpha: 0.12);
    final borderColor = waterColor.withValues(alpha: 0.2);

    return Material(
      color: emptyColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: widget.onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: AnimatedBuilder(
              animation: Listenable.merge([_wave, _fillCtrl]),
              builder: (context, _) {
                final fill = _fill.value.clamp(0.0, 1.0);
                return CustomPaint(
                  painter: _WaterPainter(
                    progress: fill,
                    phase: _wave.value * math.pi * 2,
                    color: waterColor,
                    waving: widget.waving || fill > 0 && fill < 0.98,
                  ),
                  child: SizedBox.expand(
                    child: _WaterLabel(
                      label: widget.label,
                      progress: fill,
                      dryColor: waterColor,
                      wetColor: context.colors.onPrimary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _WaterLabel extends StatelessWidget {
  final String label;
  final double progress;
  final Color dryColor;
  final Color wetColor;

  const _WaterLabel({
    required this.label,
    required this.progress,
    required this.dryColor,
    required this.wetColor,
  });

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 15, fontWeight: FontWeight.bold);
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(child: Text(label, style: style.copyWith(color: dryColor))),
        ClipRect(
          clipper: _FillClipper(progress),
          child: Center(
            child: Text(label, style: style.copyWith(color: wetColor)),
          ),
        ),
      ],
    );
  }
}

class _FillClipper extends CustomClipper<Rect> {
  final double progress;

  _FillClipper(this.progress);

  @override
  Rect getClip(Size size) {
    final height = size.height * progress.clamp(0.0, 1.0);
    return Rect.fromLTWH(0, size.height - height, size.width, height);
  }

  @override
  bool shouldReclip(_FillClipper oldClipper) => oldClipper.progress != progress;
}

class _WaterPainter extends CustomPainter {
  final double progress;
  final double phase;
  final Color color;
  final bool waving;

  _WaterPainter({
    required this.progress,
    required this.phase,
    required this.color,
    required this.waving,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final fillHeight = size.height * progress.clamp(0.0, 1.0);
    final surface = size.height - fillHeight;
    final amplitude = waving && progress < 0.97 ? 3.8 : 0.0;

    canvas.drawPath(
      _wavePath(size, surface, amplitude, phase, 1.15),
      Paint()..color = color.withValues(alpha: 0.55),
    );
    canvas.drawPath(
      _wavePath(size, surface, amplitude * 0.75, phase + 1.7, 0.85),
      Paint()..color = color,
    );
  }

  Path _wavePath(
    Size size,
    double surface,
    double amplitude,
    double phase,
    double frequency,
  ) {
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, surface);
    if (amplitude > 0) {
      const steps = 24;
      for (var i = 0; i <= steps; i++) {
        final x = size.width * i / steps;
        final y =
            surface +
            math.sin((i / steps) * math.pi * 2 * frequency + phase) *
                amplitude;
        path.lineTo(x, y);
      }
    } else {
      path.lineTo(size.width, surface);
    }
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_WaterPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.phase != phase ||
        oldDelegate.color != color ||
        oldDelegate.waving != waving;
  }
}
