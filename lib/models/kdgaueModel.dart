class KdgaueModel {
  double? currentSpeed = 0.0;

  KdgaueModel({this.currentSpeed});

  updateSpeed(double currentSpeed) {
    this.currentSpeed = currentSpeed;
  }
}
