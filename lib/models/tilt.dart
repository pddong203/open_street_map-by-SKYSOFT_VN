import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class TiltedMap extends StatelessWidget {
  final Widget child;
  final double tilt;

  const TiltedMap({Key? key, required this.child, this.tilt = 0.0})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var angle = tilt * (pi / 180);
    var matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateX(-angle);

    return Transform(
      alignment: Alignment.center,
      transform: matrix,
      child: Transform.scale(
        scale: tilt == 0.0 ? 1.0 : 2.4,
        child: child,
      ),
    );
  }
}
