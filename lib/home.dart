import 'package:flutter/material.dart';
import 'package:puzzle_game/modelo.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Modelo> vNodo = [
    Modelo(-1, -1, 'A', Colors.red, false),
    Modelo(0, -1, 'B', Colors.green, false),
    Modelo(1, -1, 'C', Colors.blue, false),
    Modelo(-1, 0, 'D', Colors.yellow, false),
    Modelo(0, 0, 'E', Colors.purple, false),
    Modelo(1, 0, 'F', Colors.orange, false),
    Modelo(-1, 1, 'G', Colors.pink, false),
    Modelo(0, 1, 'H', Colors.cyan, false),
    Modelo(1, 1, '', Colors.white, true), // Pivote
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rompekokos')),
      body: Center(
        child: SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            children: vNodo.map((nodo) {
              return AnimatedAlign(
                
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment(nodo.x, nodo.y),
                child: GestureDetector(
                  onTap: () {
                    if (nodo.esPivote) return;

                    setState(() {
                      final indexNodo = vNodo.indexOf(nodo);
                      final indexPivote = vNodo.indexWhere((n) => n.esPivote);

                      final nodoTap = vNodo[indexNodo];
                      final nodoPivote = vNodo[indexPivote];

                      // Verificar si están adyacentes
                      if (((nodoTap.x - nodoPivote.x).abs() == 1 && nodoTap.y == nodoPivote.y) ||
                          ((nodoTap.y - nodoPivote.y).abs() == 1 && nodoTap.x == nodoPivote.x)) {
                        
                        // Intercambiar coordenadas
                        final tempX = nodoTap.x;
                        final tempY = nodoTap.y;
                        nodoTap.x = nodoPivote.x;
                        nodoTap.y = nodoPivote.y;
                        nodoPivote.x = tempX;
                        nodoPivote.y = tempY;
                      }
                    });
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.all(0),
                    decoration: BoxDecoration(
                      color: nodo.color,
                      shape: BoxShape.rectangle,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),

                    ),
                    child: Center(
                      child: Text(
                        nodo.mensaje,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}