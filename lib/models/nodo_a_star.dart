import 'package:puzzle_game/models/modelo.dart';
class NodoAStar {
  final List<Modelo> estado;
  final int costo;
  final int heuristica;
  final NodoAStar? padre;

  NodoAStar(this.estado, this.costo, this.heuristica, this.padre);

  int get f => costo + heuristica;


}