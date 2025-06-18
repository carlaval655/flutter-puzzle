import '../models/modelo.dart';

int calcularHeuristica(List<Modelo> estado, List<Modelo> solucion) {
  int suma = 0;
  for (var ficha in estado) {
    if (ficha.esPivote) continue;
    final meta = solucion.firstWhere((s) => s.mensaje == ficha.mensaje);
    suma += (ficha.x - meta.x).abs().toInt() + (ficha.y - meta.y).abs().toInt();
  }
  return suma;
}