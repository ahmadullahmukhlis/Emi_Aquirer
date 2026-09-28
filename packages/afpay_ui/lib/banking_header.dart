import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared header for both tab roots and pushed banking screens.
class BankingHeader extends StatelessWidget implements PreferredSizeWidget {
  const BankingHeader({
    super.key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  final Widget title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  Widget build(BuildContext context) => ClipPath(
    clipper: _HeaderCurve(),
    child: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff043746), Color(0xff075f68), Color(0xff0a9b8f)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(right: -80, top: -90, child: _Orbit(size: 260)),
          Positioned(right: -130, top: 25, child: _Orbit(size: 310)),
          AppBar(
            title: title,
            actions: actions,
            automaticallyImplyLeading: automaticallyImplyLeading,
            toolbarHeight: 76,
            titleSpacing: 20,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            titleTextStyle: const TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w800,
              letterSpacing: -.7,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Orbit extends StatelessWidget {
  const _Orbit({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size * .55,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size),
      border: Border.all(color: Colors.white.withValues(alpha: .13)),
      color: Colors.white.withValues(alpha: .025),
    ),
  );
}

class _HeaderCurve extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..lineTo(0, size.height - 16)
    ..cubicTo(
      size.width * .22,
      size.height - 12,
      size.width * .35,
      size.height + 12,
      size.width * .60,
      size.height - 6,
    )
    ..cubicTo(
      size.width * .82,
      size.height - 24,
      size.width * .90,
      size.height - 20,
      size.width,
      size.height - 14,
    )
    ..lineTo(size.width, 0)
    ..close();
  @override
  bool shouldReclip(_HeaderCurve oldClipper) => false;
}
