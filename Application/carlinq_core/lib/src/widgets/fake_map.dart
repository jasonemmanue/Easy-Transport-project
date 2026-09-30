import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Faux widget carte utilise dans les maquettes UI/UX.
/// Sera remplace par GoogleMap SDK en Phase MVP.
class FakeMap extends StatelessWidget {
  const FakeMap({
    super.key,
    this.markers = const [],
    this.showRoute = true,
    this.height,
    this.rounded = true,
  });

  final List<FakeMarker> markers;
  final bool showRoute;
  final double? height;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final radius = rounded ? BorderRadius.circular(18) : BorderRadius.zero;
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFDCE7F5), Color(0xFFBACFED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            CustomPaint(
              size: Size.infinite,
              painter: _MapGridPainter(),
            ),
            if (showRoute)
              CustomPaint(
                size: Size.infinite,
                painter: _RoutePainter(),
              ),
            ...markers.map((m) => Align(
                  alignment: m.alignment,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _MarkerChip(marker: m),
                  ),
                )),
            Positioned(
              right: 12,
              bottom: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MapButton(icon: Icons.add, onTap: () {}),
                  const SizedBox(height: 6),
                  _MapButton(icon: Icons.remove, onTap: () {}),
                  const SizedBox(height: 6),
                  _MapButton(icon: Icons.my_location, onTap: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FakeMarker {
  const FakeMarker({
    required this.label,
    required this.alignment,
    this.color = AppColors.primary,
    this.icon = Icons.location_on,
  });
  final String label;
  final Alignment alignment;
  final Color color;
  final IconData icon;
}

class _MarkerChip extends StatelessWidget {
  const _MarkerChip({required this.marker});
  final FakeMarker marker;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(marker.icon, size: 16, color: marker.color),
              const SizedBox(width: 6),
              Text(
                marker.label,
                style: TextStyle(
                  color: marker.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_drop_down, color: marker.color, size: 20),
      ],
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1;
    const gap = 30.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.8),
      Offset(size.width * 0.9, size.height * 0.2),
      road,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.55),
      Offset(size.width, size.height * 0.55),
      road..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.8)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.4,
        size.width * 0.6,
        size.height * 0.7,
        size.width * 0.85,
        size.height * 0.2,
      );
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
