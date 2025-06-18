import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';

import 'package:puzzle_game/NodoAStar.dart';
import 'package:puzzle_game/modelo.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late List<Modelo> vNodo;
  late List<Modelo> vSolucion;
  Stopwatch cronometro = Stopwatch();
  late ConfettiController confettiController;
  Timer? timer;
  int movimientos = 0;
  int mejorTiempo = 0;

  @override
  void initState() {
    super.initState();
    _inicializarTableros();
    _mezclarFichas();
    _cargarMejorTiempo();
    confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    timer?.cancel();
    confettiController.dispose();
    super.dispose();
  }

  // ---------------------------------------
  // MÉTODOS DE INICIALIZACIÓN Y TIEMPO
  // ---------------------------------------

  Future<void> _cargarMejorTiempo() async {
    final prefs = await SharedPreferences.getInstance();
    mejorTiempo = prefs.getInt('mejorTiempo') ?? 0;
    setState(() {});
  }

  void _inicializarTableros() {
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
    _clonarSolucionComoNodo();
  }

  void _clonarSolucionComoNodo() {
    vNodo = vSolucion
        .map((e) => Modelo(e.x, e.y, e.mensaje, e.color, e.esPivote))
        .toList();
  }

  void _mezclarFichas() {
    final random = Random();
    final fichasSinPivote = vNodo.where((e) => !e.esPivote).toList()..shuffle(random);

    final posiciones = [
      [-1, -1], [0, -1], [1, -1],
      [-1, 0],  [0, 0],  [1, 0],
      [-1, 1],  [0, 1],  [1, 1],
    ];

    for (int i = 0; i < fichasSinPivote.length; i++) {
      fichasSinPivote[i].x = posiciones[i][0].toDouble();
      fichasSinPivote[i].y = posiciones[i][1].toDouble();
    }

    final pivote = vNodo.firstWhere((e) => e.esPivote);
    pivote.x = posiciones.last[0].toDouble();
    pivote.y = posiciones.last[1].toDouble();

    movimientos = 0;
    cronometro.reset();
    cronometro.start();

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    setState(() {});
  }

  // ---------------------------------------
  // LÓGICA DE JUEGO
  // ---------------------------------------

  bool _verificarVictoria() {
    for (var nodo in vNodo) {
      final solucion = vSolucion.firstWhere((s) => s.mensaje == nodo.mensaje);
      if (nodo.x != solucion.x || nodo.y != solucion.y) return false;
    }
    return true;
  }

  Future<void> _mostrarGanador() async {
    confettiController.play();
    final tiempoActual = cronometro.elapsed.inSeconds;

    if (mejorTiempo == 0 || tiempoActual < mejorTiempo) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('mejorTiempo', tiempoActual);
      mejorTiempo = tiempoActual;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("¡Felicidades! 🎉"),
        content: Text("¡Has resuelto el puzzle!\n"
            "Tiempo: ${tiempoActual}s\n"
            "Mejor tiempo: ${mejorTiempo}s"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Aceptar"),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------
  // UI
  // ---------------------------------------

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
        children: fichas.map((nodo) => _buildFicha(nodo, interactivo)).toList(),
      ),
    );
  }

  Widget _buildFicha(Modelo nodo, bool interactivo) {
    return AnimatedAlign(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment(nodo.x, nodo.y),
      child: GestureDetector(
        onTap: interactivo ? () => _moverFicha(nodo) : null,
        child: nodo.esPivote
            ? const SizedBox.shrink()
            : Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: nodo.color.withOpacity(0.85),
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    nodo.mensaje,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
      ),
    );
  }

  void _moverFicha(Modelo nodoTap) {
    final pivote = vNodo.firstWhere((n) => n.esPivote);

    if (((nodoTap.x - pivote.x).abs() == 1 && nodoTap.y == pivote.y) ||
        ((nodoTap.y - pivote.y).abs() == 1 && nodoTap.x == pivote.x)) {
      setState(() {
        final tempX = nodoTap.x;
        final tempY = nodoTap.y;
        nodoTap.x = pivote.x;
        nodoTap.y = pivote.y;
        pivote.x = tempX;
        pivote.y = tempY;
        movimientos++;

        if (_verificarVictoria()) {
          cronometro.stop();
          timer?.cancel();
          _mostrarGanador();
        }
      });
    }
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
                  children: [
                    const SizedBox(height: 20),
                    Text("Movimientos: $movimientos",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Tiempo: ${cronometro.elapsed.inSeconds}s",
                        style: const TextStyle(fontSize: 18)),
                    Text("Mejor tiempo: ${mejorTiempo > 0 ? "$mejorTiempo s" : "—"}",
                        style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 20),
                    const Text('Objetivo:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildTablero(vSolucion),
                    const SizedBox(height: 30),
                    const Text('Tu Tablero:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.brown,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.brown.shade900, blurRadius: 8)],
                      ),
                      child: _buildTablero(vNodo, interactivo: true),
                    ),
                    const SizedBox(height: 20),
                    _buildBotones(),
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

  Widget _buildBotones() {
    return Column(
      children: [
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
      ],
    );
  }

  // ---------------------------------------
  // A* PARA SOLUCIÓN AUTOMÁTICA
  // ---------------------------------------

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
        for (var paso in _obtenerCamino(actual)) {
          setState(() {
            vNodo = paso.map((e) => Modelo(e.x, e.y, e.mensaje, e.color, e.esPivote)).toList();
          });
          await Future.delayed(const Duration(milliseconds: 500));
        }
        return;
      }

      final clave = serializar(actual.estado);
      if (visitados.contains(clave)) continue;
      visitados.add(clave);

      _expandirNodos(actual, abiertos, visitados, serializar);
    }
  }

  void _expandirNodos(NodoAStar actual, List<NodoAStar> abiertos, Set<String> visitados, String Function(List<Modelo>) serializar) {
    final estado = actual.estado;
    final pivote = estado.firstWhere((e) => e.esPivote);
    final direcciones = [[0, -1], [0, 1], [-1, 0], [1, 0]];

    for (var d in direcciones) {
      final nx = pivote.x + d[0];
      final ny = pivote.y + d[1];
      final indexVecino = estado.indexWhere((e) => e.x == nx && e.y == ny);
      if (indexVecino == -1) continue;

      final nuevoEstado = estado.map((e) => Modelo(e.x, e.y, e.mensaje, e.color, e.esPivote)).toList();
      final nuevoPivote = nuevoEstado.firstWhere((e) => e.esPivote);
      final vecino = nuevoEstado[indexVecino];

      // Intercambio de posiciones
      final tempX = vecino.x, tempY = vecino.y;
      vecino.x = nuevoPivote.x;
      vecino.y = nuevoPivote.y;
      nuevoPivote.x = tempX;
      nuevoPivote.y = tempY;

      final nuevaClave = serializar(nuevoEstado);
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

  List<List<Modelo>> _obtenerCamino(NodoAStar nodo) {
    final camino = <List<Modelo>>[];
    NodoAStar? actual = nodo;
    while (actual != null) {
      camino.insert(0, actual.estado);
      actual = actual.padre;
    }
    return camino;
  }

  int calcularHeuristica(List<Modelo> estado, List<Modelo> solucion) {
    return estado
        .where((ficha) => !ficha.esPivote)
        .map((ficha) {
          final meta = solucion.firstWhere((s) => s.mensaje == ficha.mensaje);
          return (ficha.x - meta.x).abs().toInt() + (ficha.y - meta.y).abs().toInt();
        })
        .fold(0, (a, b) => a + b);
  }
}