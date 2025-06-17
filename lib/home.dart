import 'dart:math';
import 'package:flutter/material.dart';
import 'package:puzzle_game/NodoAStar.dart';
import 'package:puzzle_game/modelo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int movimientos = 0;
late Stopwatch cronometro;
int mejorTiempo = 0;
Timer? timer;
ConfettiController confettiController = ConfettiController(duration: Duration(seconds: 3));
  List<Modelo> vNodo = [];
  List<Modelo> vSolucion = [];


@override
void dispose() {
  timer?.cancel();
  confettiController.dispose();
  super.dispose();
}
  @override
  void initState() {
  super.initState();
  _initTableros();
 
  cronometro = Stopwatch();
   _mezclarFichas();
  _cargarMejorTiempo();
  }

  void _cargarMejorTiempo() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    mejorTiempo = prefs.getInt('mejorTiempo') ?? 0;
  });
}

bool _verificarVictoria() {
  for (int i = 0; i < vNodo.length; i++) {
    final nodo = vNodo[i];
    final sol = vSolucion.firstWhere((s) => s.mensaje == nodo.mensaje);
    if (nodo.x != sol.x || nodo.y != sol.y) return false;
  }
  return true;
}

void _mostrarGanador() async {
  confettiController.play();
  int tiempoActual = cronometro.elapsed.inSeconds;

  if (mejorTiempo == 0 || tiempoActual < mejorTiempo) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('mejorTiempo', tiempoActual);
    mejorTiempo = tiempoActual;
  }

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("¡Felicidades! 🎉"),
      content: Text(
          "¡Has resuelto el puzzle!\nTiempo: ${tiempoActual}s\nMejor tiempo: ${mejorTiempo}s"),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Aceptar"),
        ),
      ],
    ),
  );
}

  void _initTableros() {
    vSolucion = [
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

    // Clonamos para que vNodo sea editable
    vNodo = vSolucion.map((e) => Modelo(e.x, e.y, e.mensaje, e.color, e.esPivote)).toList();
  }

  void _mezclarFichas() {
    final random = Random();
    final fichasSinPivote = vNodo.where((e) => !e.esPivote).toList();
    fichasSinPivote.shuffle(random);

    // Posiciones posibles
    final posiciones = [
      [-1, -1], [0, -1], [1, -1],
      [-1, 0],  [0, 0],  [1, 0],
      [-1, 1],  [0, 1],  [1, 1],
    ];

    for (int i = 0; i < fichasSinPivote.length; i++) {
      fichasSinPivote[i].x = posiciones[i][0].toDouble();
      fichasSinPivote[i].y = posiciones[i][1].toDouble();
    }

    // Poner el pivote al final
    final pivote = vNodo.firstWhere((e) => e.esPivote);
    pivote.x = posiciones.last[0].toDouble();
    pivote.y = posiciones.last[1].toDouble();

movimientos = 0;
cronometro.reset();
cronometro.start();

timer?.cancel(); // Cancela cualquier anterior
timer = Timer.periodic(const Duration(seconds: 1), (_) {
  if (mounted) setState(() {});
});
    setState(() {});
  }

  Widget _buildTablero(List<Modelo> fichas, {bool interactivo = false}) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/wood.jpg'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: fichas.map((nodo) {
          return AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment(nodo.x, nodo.y),
            child: GestureDetector(
              onTap: interactivo
                  ? () {
                      if (nodo.esPivote) return;
                      setState(() {
                        final indexNodo = fichas.indexOf(nodo);
                        final indexPivote = fichas.indexWhere((n) => n.esPivote);
                        final nodoTap = fichas[indexNodo];
                        final nodoPivote = fichas[indexPivote];
                        if (((nodoTap.x - nodoPivote.x).abs() == 1 && nodoTap.y == nodoPivote.y) ||
                            ((nodoTap.y - nodoPivote.y).abs() == 1 && nodoTap.x == nodoPivote.x)) {
                          final tempX = nodoTap.x;
                          final tempY = nodoTap.y;
                          nodoTap.x = nodoPivote.x;
                          nodoTap.y = nodoPivote.y;
                          nodoPivote.x = tempX;
                          nodoPivote.y = tempY;
                          movimientos++;
if (_verificarVictoria()) {
  cronometro.stop();
  timer?.cancel();
  _mostrarGanador();
}
                        }
                      });
                    }
                  : null,
              child: nodo.esPivote
    ? const SizedBox.shrink()
    : Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: nodo.color.withOpacity(0.85),
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            nodo.mensaje,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 197, 165, 143),
      appBar: AppBar(
        title: const Text('Rompekokos'),
        backgroundColor: Colors.brown,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ConfettiWidget(
  confettiController: confettiController,
  blastDirectionality: BlastDirectionality.explosive,
  shouldLoop: false,
),
          SafeArea(
            child: SingleChildScrollView(
              child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
Text(
  "Movimientos: $movimientos",
  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
Text(
  "Tiempo: ${cronometro.elapsed.inSeconds}s",
  style: const TextStyle(fontSize: 18),
),
Text(
  "Mejor tiempo: ${mejorTiempo > 0 ? "$mejorTiempo s" : "—"}",
  style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
),
const SizedBox(height: 20),
              const SizedBox(height: 20),
              const Text(
                'Objetivo:',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildTablero(vSolucion, interactivo: false),
              const SizedBox(height: 30),
              const Text(
                'Tu Tablero:',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.brown,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.shade900,
                      blurRadius: 8,
                      offset: const Offset(4, 4),
                    )
                  ],
                ),
                child: _buildTablero(vNodo, interactivo: true),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _mezclarFichas,
                icon: const Icon(Icons.shuffle),
                label: const Text("Mezclar fichas"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: resolverPuzzleConAEstrella,
                icon: const Icon(Icons.lightbulb),
                label: const Text("Resolver automáticamente"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> resolverPuzzleConAEstrella() async {
  Set<String> visitados = {};
  List<NodoAStar> abiertos = [];

  String serializar(List<Modelo> estado) =>
      estado.map((e) => '${e.mensaje}:${e.x},${e.y}').join('|');

  abiertos.add(NodoAStar(
    vNodo.map((e) => Modelo(e.x, e.y, e.mensaje, e.color, e.esPivote)).toList(),
    0,
    calcularHeuristica(vNodo, vSolucion),
    null,
  ));

  while (abiertos.isNotEmpty) {
    abiertos.sort((a, b) => a.f.compareTo(b.f));
    NodoAStar actual = abiertos.removeAt(0);

    if (calcularHeuristica(actual.estado, vSolucion) == 0) {
      // Encontrado
      List<List<Modelo>> camino = [];
      NodoAStar? nodo = actual;
      while (nodo != null) {
        camino.insert(0, nodo.estado);
        nodo = nodo.padre;
      }

      for (var paso in camino) {
        setState(() {
          vNodo = paso
              .map((e) => Modelo(e.x, e.y, e.mensaje, e.color, e.esPivote))
              .toList();
        });
        await Future.delayed(const Duration(milliseconds: 500));
      }

      return;
    }

    String clave = serializar(actual.estado);
    if (visitados.contains(clave)) continue;
    visitados.add(clave);

    List<Modelo> estadoActual = actual.estado;
    int indexPivote = estadoActual.indexWhere((e) => e.esPivote);
    Modelo pivote = estadoActual[indexPivote];

    List<List<int>> direcciones = [
      [0, -1],
      [0, 1],
      [-1, 0],
      [1, 0],
    ];

    for (var d in direcciones) {
      double nx = pivote.x + d[0];
      double ny = pivote.y + d[1];

      int? indexVecino = estadoActual.indexWhere((e) => e.x == nx && e.y == ny);
      if (indexVecino == -1) continue;

      List<Modelo> nuevoEstado = estadoActual
          .map((e) => Modelo(e.x, e.y, e.mensaje, e.color, e.esPivote))
          .toList();

      Modelo nuevoPivote = nuevoEstado.firstWhere((e) => e.esPivote);
      Modelo vecino = nuevoEstado.firstWhere((e) => e.x == nx && e.y == ny);

      double tempX = vecino.x;
      double tempY = vecino.y;
      vecino.x = nuevoPivote.x;
      vecino.y = nuevoPivote.y;
      nuevoPivote.x = tempX;
      nuevoPivote.y = tempY;

      String nuevaClave = serializar(nuevoEstado);
      if (!visitados.contains(nuevaClave)) {
        abiertos.add(NodoAStar(
          nuevoEstado,
          actual.costo + 1,
          calcularHeuristica(nuevoEstado, vSolucion),
          actual,
        ));
      }
    }
  }
}

  int calcularHeuristica(List<Modelo> estado, List<Modelo> solucion) {
  int suma = 0;
  for (var ficha in estado) {
    if (ficha.esPivote) continue;

    var meta = solucion.firstWhere((s) => s.mensaje == ficha.mensaje);
    suma += (ficha.x - meta.x).abs().toInt() + (ficha.y - meta.y).abs().toInt();
  }
  return suma;
}
}