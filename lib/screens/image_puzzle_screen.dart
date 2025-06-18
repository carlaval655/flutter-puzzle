import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/modelo.dart';
import '../widgets/board_widget.dart';

class ImagePuzzleScreen extends StatefulWidget {
  const ImagePuzzleScreen({super.key});

  @override
  State<ImagePuzzleScreen> createState() => _ImagePuzzleScreenState();
}

class _ImagePuzzleScreenState extends State<ImagePuzzleScreen> {
  File? _imageFile;
  List<Modelo> _piezasPuzzle = [];

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, maxWidth: 600);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      setState(() {
        _imageFile = file;
        _piezasPuzzle = [];
      });
      await _procesarImagen(file);
    }
  }

  Future<ui.Image> _loadUiImage(File file) async {
    final data = await file.readAsBytes();
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(data, (img) {
      completer.complete(img);
    });
    return completer.future;
  }

  Future<List<Modelo>> _dividirImagenEnPiezas(ui.Image image) async {
    final piezas = <Modelo>[];
    const int filas = 3;
    const int columnas = 3;

    final double anchoPieza = image.width / columnas;
    final double altoPieza = image.height / filas;

    for (int fila = 0; fila < filas; fila++) {
      for (int col = 0; col < columnas; col++) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        final srcRect =
            Rect.fromLTWH(col * anchoPieza, fila * altoPieza, anchoPieza, altoPieza);
        final dstRect = Rect.fromLTWH(0, 0, anchoPieza, altoPieza);

        canvas.drawImageRect(image, srcRect, dstRect, Paint());
        final picture = recorder.endRecording();
        final img = await picture.toImage(anchoPieza.toInt(), altoPieza.toInt());

        final mensaje = String.fromCharCode(65 + fila * columnas + col); // A,B,C...
        piezas.add(Modelo(col - 1, fila - 1, mensaje, null, false,
            imagenRecortada: img));
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
      _piezasPuzzle = piezas;
    });
  }

  bool _verificarVictoria() {
    for (int i = 0; i < _piezasPuzzle.length; i++) {
      final nodo = _piezasPuzzle[i];
      final meta = _piezasPuzzle.firstWhere((e) => e.mensaje == nodo.mensaje);
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
                    if (_verificarVictoria()) {
                      _mostrarGanador();
                    }
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Tomar una foto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}