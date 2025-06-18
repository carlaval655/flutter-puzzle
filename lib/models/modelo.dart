import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class Modelo {
  double x;
  double y;
  String mensaje;
  Color? color;
  bool esPivote;
  ui.Image? imagenRecortada; // nueva propiedad para imagen

  Modelo(this.x, this.y, this.mensaje, this.color, this.esPivote, {this.imagenRecortada});

  Modelo copy() {
    return Modelo(x, y, mensaje, color, esPivote, imagenRecortada: imagenRecortada);
  }
}