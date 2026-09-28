import 'dart:math' as math;

import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 54, this.withContainer = false});
  final double size;
  final bool withContainer;
  @override
  Widget build(BuildContext context) {
    final mark = CustomPaint(
      size: Size.square(size),
      painter: const _BrandMarkPainter(),
    );
    if (!withContainer) return mark;
    return Container(
      width: size + 38,
      height: size + 38,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x240544cc),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: mark,
    );
  }
}

class BrandRibbonBackground extends StatelessWidget {
  const BrandRibbonBackground({super.key, this.login = false});
  final bool login;
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _RibbonPainter(login: login),
    size: Size.infinite,
  );
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    void petal(Color color, double rotation, double scale) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);
      canvas.scale(scale);
      final rect = Rect.fromCenter(
        center: Offset(0, -size.height * .14),
        width: size.width * .34,
        height: size.height * .58,
      );
      final path = Path()
        ..moveTo(0, rect.bottom)
        ..cubicTo(
          rect.left * 1.2,
          rect.height * .10,
          rect.left,
          rect.top,
          0,
          rect.top,
        )
        ..cubicTo(
          rect.right,
          rect.top,
          rect.right * 1.2,
          rect.height * .10,
          0,
          rect.bottom,
        )
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: .65), color],
          ).createShader(rect),
      );
      canvas.restore();
    }

    petal(const Color(0xff0070f5), -.72, .95);
    petal(const Color(0xff00bce8), 0, 1.0);
    petal(const Color(0xff1544e8), .72, .95);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter({required this.login});
  final bool login;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xfffbfdff), Color(0xffe9f3ff), Color(0xfffbfdff)],
        ).createShader(Offset.zero & size),
    );
    void ribbon(
      List<Color> colors,
      double y,
      double amp,
      double phase,
      double thickness,
      double opacity,
    ) {
      final path = Path()..moveTo(-size.width * .15, y);
      for (double x = -size.width * .15; x <= size.width * 1.15; x += 4) {
        path.lineTo(
          x,
          y + math.sin((x / size.width * math.pi * 1.65) + phase) * amp,
        );
      }
      for (double x = size.width * 1.15; x >= -size.width * .15; x -= 4) {
        path.lineTo(
          x,
          y +
              thickness +
              math.sin((x / size.width * math.pi * 1.65) + phase + .7) * amp,
        );
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..shader =
              LinearGradient(
                colors: colors
                    .map((c) => c.withValues(alpha: opacity))
                    .toList(),
              ).createShader(
                Rect.fromLTWH(0, y - amp, size.width, thickness + amp * 2),
              ),
      );
    }

    if (login) {
      ribbon(
        const [Color(0xffb8dbff), Color(0xffeef6ff)],
        size.height * .08,
        36,
        .6,
        72,
        .8,
      );
      ribbon(
        const [Color(0xff4593fa), Color(0xffc9e4ff)],
        size.height * .18,
        42,
        2.2,
        66,
        .5,
      );
      ribbon(
        const [Color(0xff1c55ef), Color(0xff43d1f4)],
        size.height * .26,
        44,
        .1,
        68,
        .72,
      );
    } else {
      ribbon(
        const [Color(0xffddecff), Color(0xfff8fbff)],
        size.height * .10,
        40,
        .6,
        72,
        .9,
      );
      ribbon(
        const [Color(0xff75b5ff), Color(0xffedf6ff)],
        size.height * .24,
        46,
        2.0,
        92,
        .65,
      );
      ribbon(
        const [Color(0xff1759ee), Color(0xff3dd0f2)],
        size.height * .42,
        50,
        .2,
        92,
        .82,
      );
      ribbon(
        const [Color(0xff60c9f4), Color(0xffd8edff)],
        size.height * .58,
        38,
        2.6,
        72,
        .62,
      );
      ribbon(
        const [Color(0xfff8fbff), Color(0xffd8eaff)],
        size.height * .76,
        45,
        .4,
        104,
        .88,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter oldDelegate) =>
      oldDelegate.login != login;
}
