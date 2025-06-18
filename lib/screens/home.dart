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
        content: Text("¡Puzzle resuelto!\nTiempo: ${tiempoActual}s\nMejor: ${mejorTiempo}s"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Aceptar"),
          )
        ],
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

  Future<void> _resolverAutomaticamente() async {
    await resolverPuzzleConAEstrella(
      context: context,
      tableroActual: tableroActual,
      tableroSolucion: tableroSolucion,
      onStep: (paso) async {
        setState(() {
          tableroActual = paso.map((e) => e.copy()).toList();
        });
        await Future.delayed(const Duration(milliseconds: 500));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[300],
      appBar: AppBar(
        title: const Text('Rompekokos'),
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
                    Text("Movimientos: $movimientos"),
                    Text("Tiempo: ${cronometro.elapsed.inSeconds}s"),
                    Text("Mejor tiempo: ${mejorTiempo > 0 ? "$mejorTiempo s" : "—"}"),
                    const SizedBox(height: 20),
                    const Text("Tu Tablero:"),
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
                    ),
                    ElevatedButton.icon(
                      onPressed: _mezclarTablero,
                      icon: const Icon(Icons.shuffle),
                      label: const Text("Mezclar fichas"),
                    ),
                    ElevatedButton.icon(
                      onPressed: _resolverAutomaticamente,
                      icon: const Icon(Icons.lightbulb),
                      label: const Text("Resolver automáticamente"),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  
}