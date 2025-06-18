// 📁 lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:puzzle_game/models/nodo_a_star.dart';
import 'package:puzzle_game/widgets/board_widget.dart';
import 'package:puzzle_game/models/modelo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool resolviendo = false;
  late Stopwatch cronometro;
  late ConfettiController confettiController;
  Timer? timer;

  List<Modelo> tableroActual = [];
  List<Modelo> tableroSolucion = [];

  int movimientos = 0;
  int mejorTiempo = 0;

  @override
  void initState() {
    super.initState();
    cronometro = Stopwatch();
    confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _inicializarTableros();
    _mezclarTablero();
    _cargarMejorTiempo();
  }

  @override
  void dispose() {
    timer?.cancel();
    confettiController.dispose();
    super.dispose();
  }

  void _inicializarTableros() {
    tableroSolucion = [
      Modelo(-1, -1, 'A', Colors.red, false),
      Modelo(0, -1, 'B', Colors.green, false),
      Modelo(1, -1, 'C', Colors.blue, false),
      Modelo(-1, 0, 'D', Colors.yellow, false),
      Modelo(0, 0, 'E', Colors.purple, false),
      Modelo(1, 0, 'F', Colors.orange, false),
      Modelo(-1, 1, 'G', Colors.pink, false),
      Modelo(0, 1, 'H', Colors.cyan, false),
      Modelo(1, 1, '', Colors.white, true),
    ];

    tableroActual = tableroSolucion.map((f) => f.copy()).toList();
  }

  void _mezclarTablero() {
    final random = Random();
    final fichas = tableroActual.where((f) => !f.esPivote).toList();
    fichas.shuffle(random);

    final posiciones = [
      [-1, -1], [0, -1], [1, -1],
      [-1, 0],  [0, 0],  [1, 0],
      [-1, 1],  [0, 1],  [1, 1],
    ];

    for (int i = 0; i < fichas.length; i++) {
      fichas[i].x = posiciones[i][0].toDouble();
      fichas[i].y = posiciones[i][1].toDouble();
    }

    final pivote = tableroActual.firstWhere((f) => f.esPivote);
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

  void _cargarMejorTiempo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      mejorTiempo = prefs.getInt('mejorTiempo') ?? 0;
    });
  }

  bool _verificarVictoria() {
    for (int i = 0; i < tableroActual.length; i++) {
      final nodo = tableroActual[i];
      final sol = tableroSolucion.firstWhere((s) => s.mensaje == nodo.mensaje);
      if (nodo.x != sol.x || nodo.y != sol.y) return false;
    }
    return true;
  }

  void _mostrarGanador() async {
    confettiController.play( );
    int tiempoActual = cronometro.elapsed.inSeconds;

showDialog(
  context: context,
  builder: (_) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    backgroundColor: Colors.brown[50],
    title: Column(
      children: const [
        Icon(Icons.celebration, color: Colors.green, size: 48),
        SizedBox(height: 10),
        Text(
          "¡Felicidades! 🎉",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
      ],
    ),
    content: Text(
      "🧩 Puzzle resuelto exitosamente\n⏱️ Tiempo: ${cronometro.elapsed.inSeconds}s",
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 18),
    ),
    actions: [
      Center(
        child: ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.check_circle),
          label: const Text("Aceptar"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      )
    ],
    actionsAlignment: MainAxisAlignment.center,
  ),
);
  }

  void _mostrarSolucionEnModal() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tablero objetivo"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BoardWidget(fichas: tableroSolucion),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  Future<void> resolverPuzzleConAEstrella({
    required BuildContext context,
    required List<Modelo> tableroActual,
    required List<Modelo> tableroSolucion,
    required Future<void> Function(List<Modelo>) onStep,
  }) async {
    const int maxIteraciones = 10000;
    int iteraciones = 0;

    Set<String> visitados = {};
    List<NodoAStar> abiertos = [];

    String serializar(List<Modelo> estado) =>
        estado.map((e) => '${e.mensaje}:${e.x},${e.y}').join('|');

    abiertos.add(NodoAStar(
      tableroActual.map((e) => e.copy()).toList(),
      0,
      _calcularHeuristica(tableroActual, tableroSolucion),
      null,
    ));

    while (abiertos.isNotEmpty) {
      if (iteraciones++ > maxIteraciones) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⏱️ No se encontró una solución en un tiempo razonable."),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,)
        );
        return;
      }

      abiertos.sort((a, b) => a.f.compareTo(b.f));
      NodoAStar actual = abiertos.removeAt(0);

      if (_calcularHeuristica(actual.estado, tableroSolucion) == 0) {
        List<List<Modelo>> camino = [];
        NodoAStar? nodo = actual;
        while (nodo != null) {
          camino.insert(0, nodo.estado);
          nodo = nodo.padre;
        }

for (var paso in camino) {
  await onStep(paso);
}

// 🚨 Detener cronómetro y timer si lo resolvió automáticamente
cronometro.stop();
timer?.cancel();
_mostrarGanador();
return;
      }

      String clave = serializar(actual.estado);
      if (visitados.contains(clave)) continue;
      visitados.add(clave);

      List<Modelo> estadoActual = actual.estado;
      int indexPivote = estadoActual.indexWhere((e) => e.esPivote);
      Modelo pivote = estadoActual[indexPivote];

      List<List<int>> direcciones = [
        [0, -1], [0, 1], [-1, 0], [1, 0]
      ];

      for (var d in direcciones) {
        double nx = pivote.x + d[0];
        double ny = pivote.y + d[1];

        int? indexVecino = estadoActual.indexWhere((e) => e.x == nx && e.y == ny);
        if (indexVecino == -1) continue;

        List<Modelo> nuevoEstado = estadoActual.map((e) => e.copy()).toList();

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
            _calcularHeuristica(nuevoEstado, tableroSolucion),
            actual,
          ));
        }
      }
    }
  }

  int _calcularHeuristica(List<Modelo> estado, List<Modelo> solucion) {
    int suma = 0;
    for (var ficha in estado) {
      if (ficha.esPivote) continue;
      var meta = solucion.firstWhere((s) => s.mensaje == ficha.mensaje);
      suma += (ficha.x - meta.x).abs().toInt() + (ficha.y - meta.y).abs().toInt();
    }
    return suma;
  }

  Future<void> _resolverAutomaticamente() async {
    if (resolviendo) return;
    setState(() => resolviendo = true);

    try {
      await resolverPuzzleConAEstrella(
        context: context,
        tableroActual: tableroActual,
        tableroSolucion: tableroSolucion,
        onStep: (paso) async {
          if (!resolviendo) throw 'cancelado';
          setState(() {
            tableroActual = paso.map((e) => e.copy()).toList();
          });
          await Future.delayed(const Duration(milliseconds: 300));
        },
      );
    } catch (e) {
      if (e == 'cancelado') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resolución cancelada.')),
        );
      }
    } finally {
      setState(() => resolviendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBCAAA4),
      appBar: AppBar(
        backgroundColor: Colors.brown[700],
        title: const Text('Rompecabezas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Text("Movimientos: $movimientos",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Tiempo: ${cronometro.elapsed.inSeconds}s",
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 20),
                      const Text("Tu Tablero:",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      BoardWidget(
                        fichas: tableroActual,
                        interactivo: true,
                        onCambio: (nuevoTablero) {
                          setState(() {
                            tableroActual = nuevoTablero;
                            movimientos++;
                            if (_verificarVictoria()) {
                              cronometro.stop();
                              timer?.cancel();
                              _mostrarGanador();
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _mostrarSolucionEnModal,
                        icon: const Icon(Icons.visibility),
                        label: const Text("Ver objetivo"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[500],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _mezclarTablero,
                        icon: const Icon(Icons.shuffle),
                        label: const Text("Mezclar fichas"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _resolverAutomaticamente,
                        icon: const Icon(Icons.lightbulb),
                        label: const Text("Resolver automáticamente"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                      if (resolviendo)
                        ElevatedButton.icon(
                          onPressed: () => setState(() => resolviendo = false),
                          icon: const Icon(Icons.cancel),
                          label: const Text("Cancelar resolución"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}