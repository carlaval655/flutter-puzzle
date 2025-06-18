import 'package:flutter/material.dart';
import '../models/modelo.dart';

class BoardWidget extends StatelessWidget {
  final List<Modelo> fichas;
  final bool interactivo;
  final void Function(List<Modelo>)? onCambio;

  const BoardWidget({
    super.key,
    required this.fichas,
    this.interactivo = false,
    this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/wood.jpg'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: fichas.map((ficha) {
          return AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment(ficha.x, ficha.y),
            child: GestureDetector(
              onTap: () {
                if (!interactivo || ficha.esPivote) return;

                final pivote = fichas.firstWhere((f) => f.esPivote);
                final dx = (ficha.x - pivote.x).abs();
                final dy = (ficha.y - pivote.y).abs();
                final esAdyacente = (dx == 1 && dy == 0) || (dx == 0 && dy == 1);
                if (!esAdyacente) return;

                final nuevoTablero = fichas.map((f) => f.copy()).toList();
                final fichaMovida = nuevoTablero.firstWhere((f) => f.mensaje == ficha.mensaje);
                final pivoteNuevo = nuevoTablero.firstWhere((f) => f.esPivote);

                final tempX = fichaMovida.x;
                final tempY = fichaMovida.y;
                fichaMovida.x = pivoteNuevo.x;
                fichaMovida.y = pivoteNuevo.y;
                pivoteNuevo.x = tempX;
                pivoteNuevo.y = tempY;

                if (onCambio != null) onCambio!(nuevoTablero);
              },
              child: ficha.esPivote
                  ? const SizedBox.shrink()
                  : SizedBox(
                      width: 100,
                      height: 100,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ficha.imagenRecortada != null
                            ? FittedBox(
                                fit: BoxFit.fill,
                                child: RawImage(
                                  image: ficha.imagenRecortada!,
                                ),
                              )
                            : Container(
                                color: ficha.color ?? Colors.transparent,
                                child: Center(
                                  child: Text(
                                    ficha.mensaje,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }
}