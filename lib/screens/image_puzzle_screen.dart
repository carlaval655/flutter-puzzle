import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/modelo.dart';
import '../widgets/board_widget.dart';
import '../models/nodo_a_star.dart';

class ImagePuzzleScreen extends StatefulWidget {
  const ImagePuzzleScreen({super.key});

  @override
  State<ImagePuzzleScreen> createState() => _ImagePuzzleScreenState();
}

class _ImagePuzzleScreenState extends State<ImagePuzzleScreen> {
  File? _imageFile;
  List<Modelo> _piezasPuzzle = [];
  List<Modelo> _piezasSolucion = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, maxWidth: 600);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      setState(() {
        _imageFile = file;
        _piezasPuzzle = [];
        _piezasSolucion = [];
      });
      await _procesarImagen(file);
    }
  }

  Future<ui.Image> _loadUiImage(File file) async {
    final data = await file.readAsBytes();
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(data, (img) => completer.complete(img));
    return completer.future;
  }

  Future<List<Modelo>> _dividirImagenEnPiezas(ui.Image image) async {
    const filas = 3;
    const columnas = 3;
    final piezas = <Modelo>[];

    final anchoPieza = image.width / columnas;
    final altoPieza = image.height / filas;

    for (int fila = 0; fila < filas; fila++) {
      for (int col = 0; col < columnas; col++) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        final src = Rect.fromLTWH(col * anchoPieza, fila * altoPieza, anchoPieza, altoPieza);
        final dst = Rect.fromLTWH(0, 0, anchoPieza, altoPieza);

        canvas.drawImageRect(image, src, dst, Paint());
        final picture = recorder.endRecording();
        final img = await picture.toImage(anchoPieza.toInt(), altoPieza.toInt());

        final letra = String.fromCharCode(65 + fila * columnas + col); // A, B, ...
        piezas.add(Modelo(col - 1, fila - 1, letra, null, false, imagenRecortada: img));
      }
    }

    piezas.last.esPivote = true;
    piezas.last.mensaje = '';
    return piezas;
  }

  Future<void> _procesarImagen(File file) async {
    final uiImage = await _loadUiImage(file);
    final piezas = await _dividirImagenEnPiezas(uiImage);
    setState(() {
      _piezasPuzzle = piezas.map((e) => e.copy()).toList();
      _piezasSolucion = piezas.map((e) => e.copy()).toList();
    });
  }

  void _mezclarFichas() {
    final random = Random();
    final fichas = _piezasPuzzle.where((f) => !f.esPivote).toList();
    fichas.shuffle(random);

    final posiciones = [
      [-1, -1], [0, -1], [1, -1],
      [-1, 0], [0, 0], [1, 0],
      [-1, 1], [0, 1], [1, 1],
    ];

    for (int i = 0; i < fichas.length; i++) {
      fichas[i].x = posiciones[i][0].toDouble();
      fichas[i].y = posiciones[i][1].toDouble();
    }

    final pivote = _piezasPuzzle.firstWhere((f) => f.esPivote);
    pivote.x = posiciones.last[0].toDouble();
    pivote.y = posiciones.last[1].toDouble();

    setState(() {});
  }

  bool _verificarVictoria() {
    for (var nodo in _piezasPuzzle) {
      final meta = _piezasSolucion.firstWhere((e) => e.mensaje == nodo.mensaje);
      if (nodo.x != meta.x || nodo.y != meta.y) return false;
    }
    return true;
  }

  void _mostrarGanador() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("¡Felicidades! 🎉"),
        content: const Text("¡Has resuelto el rompecabezas con imagen!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Aceptar"),
          ),
        ],
      ),
    );
  }

  void _mostrarSolucion() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Solución"),
        content: BoardWidget(fichas: _piezasSolucion),
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
    Set<String> visitados = {};
    List<NodoAStar> abiertos = [];
    const int maxIteraciones = 20000;
    int iteraciones = 0;

    String serializar(List<Modelo> estado) =>
        estado.map((e) => '${e.mensaje}:${e.x},${e.y}').join('|');

    List<Modelo> inicial = _piezasPuzzle.map((e) => Modelo(e.x, e.y, e.mensaje, null, e.esPivote)).toList();
    List<Modelo> solucion = _piezasSolucion.map((e) => Modelo(e.x, e.y, e.mensaje, null, e.esPivote)).toList();

    abiertos.add(NodoAStar(inicial, 0, _calcularHeuristica(inicial, solucion), null));

    while (abiertos.isNotEmpty) {
      if (iteraciones++ > maxIteraciones) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⏱️ No se encontró una solución en un tiempo razonable.")),
        );
        return;
      }

      abiertos.sort((a, b) => a.f.compareTo(b.f));
      NodoAStar actual = abiertos.removeAt(0);

      if (_calcularHeuristica(actual.estado, solucion) == 0) {
        List<List<Modelo>> camino = [];
        NodoAStar? nodo = actual;
        while (nodo != null) {
          camino.insert(0, nodo.estado);
          nodo = nodo.padre;
        }

        for (var paso in camino) {
          setState(() {
            _piezasPuzzle = paso.map((e) {
              final original = _piezasPuzzle.firstWhere((m) => m.mensaje == e.mensaje);
              return Modelo(e.x, e.y, e.mensaje, null, e.esPivote, imagenRecortada: original.imagenRecortada);
            }).toList();
          });
          await Future.delayed(const Duration(milliseconds: 300));
        }
        return;
      }

      String clave = serializar(actual.estado);
      if (visitados.contains(clave)) continue;
      visitados.add(clave);

      final pivote = actual.estado.firstWhere((e) => e.esPivote);
      final direcciones = [[0, -1], [0, 1], [-1, 0], [1, 0]];

      for (var d in direcciones) {
        double nx = pivote.x + d[0];
        double ny = pivote.y + d[1];
        int iVecino = actual.estado.indexWhere((e) => e.x == nx && e.y == ny);
        if (iVecino == -1) continue;

        var nuevoEstado = actual.estado.map((e) => Modelo(e.x, e.y, e.mensaje, null, e.esPivote)).toList();

        var nuevoPivote = nuevoEstado.firstWhere((e) => e.esPivote);
        var vecino = nuevoEstado[iVecino];

        final tempX = vecino.x;
        final tempY = vecino.y;
        vecino.x = nuevoPivote.x;
        vecino.y = nuevoPivote.y;
        nuevoPivote.x = tempX;
        nuevoPivote.y = tempY;

        String nuevaClave = serializar(nuevoEstado);
        if (!visitados.contains(nuevaClave)) {
          abiertos.add(NodoAStar(
            nuevoEstado,
            actual.costo + 1,
            _calcularHeuristica(nuevoEstado, solucion),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rompecabezas con imagen'),
        centerTitle: true,
        backgroundColor: Colors.teal[600],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_piezasPuzzle.isNotEmpty)
              BoardWidget(
                fichas: _piezasPuzzle,
                interactivo: true,
                onCambio: (nuevoTablero) {
                  setState(() {
                    _piezasPuzzle = nuevoTablero;
                    if (_verificarVictoria()) _mostrarGanador();
                  });
                },
              )
            else if (_imageFile != null)
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.teal, width: 2),
                  image: DecorationImage(
                    image: FileImage(_imageFile!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              const Text(
                'Selecciona una imagen para comenzar',
                style: TextStyle(fontSize: 18),
              ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Seleccionar de galería'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[400],
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Tomar una foto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700],
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            if (_piezasPuzzle.isNotEmpty) ...[
              ElevatedButton.icon(
                onPressed: _mezclarFichas,
                icon: const Icon(Icons.shuffle),
                label: const Text('Mezclar fichas'),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _mostrarSolucion,
                icon: const Icon(Icons.visibility),
                label: const Text('Ver solución'),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _resolverAutomaticamente,
                icon: const Icon(Icons.lightbulb),
                label: const Text('Resolver automáticamente'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }
}