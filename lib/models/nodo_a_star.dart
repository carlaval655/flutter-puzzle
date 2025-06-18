import 'package:flutter/material.dart';
import '../models/modelo.dart';
import '../utils/heuristics.dart';

class NodoAStar {
  final List<Modelo> estado;
  final int costo;
  final int heuristica;
  final NodoAStar? padre;

  NodoAStar(this.estado, this.costo, this.heuristica, this.padre);

  int get f => costo + heuristica;
}

Future<void> resolverPuzzleConAEstrella({
  required BuildContext context,
  required List<Modelo> tableroActual,
  required List<Modelo> tableroSolucion,
  required Future<void> Function(List<Modelo> paso) onStep,
}) async {
  Set<String> visitados = {};
  List<NodoAStar> abiertos = [];

  String serializar(List<Modelo> estado) =>
      estado.map((e) => '${e.mensaje}:${e.x},${e.y}').join('|');

  abiertos.add(NodoAStar(
    tableroActual.map((e) => e.copy()).toList(),
    0,
    calcularHeuristica(tableroActual, tableroSolucion),
    null,
  ));

  while (abiertos.isNotEmpty) {
    abiertos.sort((a, b) => a.f.compareTo(b.f));
    NodoAStar actual = abiertos.removeAt(0);

    if (calcularHeuristica(actual.estado, tableroSolucion) == 0) {
      List<List<Modelo>> camino = [];
      NodoAStar? nodo = actual;
      while (nodo != null) {
        camino.insert(0, nodo.estado);
        nodo = nodo.padre;
      }

      for (var paso in camino) {
        await onStep(paso);
      }
      return;
    }

    String clave = serializar(actual.estado);
    if (visitados.contains(clave)) continue;
    visitados.add(clave);

    final estado = actual.estado;
    final pivote = estado.firstWhere((e) => e.esPivote);

    final direcciones = [
      [0, -1],
      [0, 1],
      [-1, 0],
      [1, 0],
    ];

    for (var d in direcciones) {
      final nx = pivote.x + d[0];
      final ny = pivote.y + d[1];
      final indexVecino = estado.indexWhere((e) => e.x == nx && e.y == ny);
      if (indexVecino == -1) continue;

      final nuevoEstado = estado.map((e) => e.copy()).toList();
      final nuevoPivote = nuevoEstado.firstWhere((e) => e.esPivote);
      final vecino = nuevoEstado[indexVecino];

      final tempX = vecino.x;
      final tempY = vecino.y;
      vecino.x = nuevoPivote.x;
      vecino.y = nuevoPivote.y;
      nuevoPivote.x = tempX;
      nuevoPivote.y = tempY;

      final nuevaClave = serializar(nuevoEstado);
      if (!visitados.contains(nuevaClave)) {
        abiertos.add(NodoAStar(
          nuevoEstado,
          actual.costo + 1,
          calcularHeuristica(nuevoEstado, tableroSolucion),
          actual,
        ));
      }
    }
  }
}