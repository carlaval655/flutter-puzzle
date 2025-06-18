import 'package:flutter/material.dart';
class Modelo {
  double x, y;
  String mensaje;
  Color color;
  bool esPivote;
  Modelo(this.x, this.y, this.mensaje, this.color, this.esPivote);

  Modelo copy() {
    return Modelo(x, y, mensaje, color, esPivote);
  }
}