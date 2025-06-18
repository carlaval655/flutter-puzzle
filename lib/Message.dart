import 'dart:isolate';

import 'package:puzzle_game/modelo.dart';

class _Message {
  final List<Modelo> tableroActual;
  final List<Modelo> tableroSolucion;
  final SendPort sendPort;

  _Message(this.tableroActual, this.tableroSolucion, this.sendPort);
}