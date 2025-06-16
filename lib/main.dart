import 'dart:math';

import 'package:flutter/material.dart';


void main() {
  runApp(const PuzzleApp());
}

class PuzzleApp extends StatelessWidget {
  const PuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rompecabezas',
      debugShowCheckedModeBanner: false,
      home: const PuzzleHome(),
    );
  }
}

enum GameMode { image, simple }

class PuzzleHome extends StatefulWidget {
  const PuzzleHome({super.key});

  @override
  State<PuzzleHome> createState() => _PuzzleHomeState();
}

class _PuzzleHomeState extends State<PuzzleHome> {
  static const int gridSize = 3;
  late List<int> tiles;
  GameMode _mode = GameMode.image;

  @override
  void initState() {
    super.initState();
    _shuffleTiles();
  }

  void _shuffleTiles() {
    tiles = List<int>.generate(gridSize * gridSize, (index) => index);
    do {
      tiles.shuffle(Random());
    } while (!_isSolvable(tiles));
  }

  bool _isSolvable(List<int> tiles) {
    int inversions = 0;
    for (int i = 0; i < tiles.length; i++) {
      for (int j = i + 1; j < tiles.length; j++) {
        if (tiles[i] != 0 && tiles[j] != 0 && tiles[i] > tiles[j]) {
          inversions++;
        }
      }
    }
    return inversions % 2 == 0;
  }

  void _onTileTap(int index) {
    int emptyIndex = tiles.indexOf(0);
    int row = index ~/ gridSize;
    int col = index % gridSize;
    int emptyRow = emptyIndex ~/ gridSize;
    int emptyCol = emptyIndex % gridSize;

    if ((row == emptyRow && (col - emptyCol).abs() == 1) ||
        (col == emptyCol && (row - emptyRow).abs() == 1)) {
      setState(() {
        tiles[emptyIndex] = tiles[index];
        tiles[index] = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.asset('assets/images/puzzle.jpg',
        fit: BoxFit.cover, gaplessPlayback: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rompecabezas 3x3'),
        actions: [
          DropdownButton<GameMode>(
            value: _mode,
            underline: const SizedBox(),
            onChanged: (GameMode? newMode) {
              if (newMode != null) {
                setState(() {
                  _mode = newMode;
                  _shuffleTiles();
                });
              }
            },
            items: const [
              DropdownMenuItem(
                value: GameMode.image,
                child: Text("🖼️ Imagen"),
              ),
              DropdownMenuItem(
                value: GameMode.simple,
                child: Text("🔤 Letras y colores"),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _shuffleTiles();
              });
            },
          )
        ],
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            itemCount: tiles.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridSize,
            ),
            itemBuilder: (context, index) {
              int tileNumber = tiles[index];
              if (tileNumber == 0) {
                return Container(color: Colors.grey[300]);
              } else {
                return GestureDetector(
                  onTap: () => _onTileTap(index),
                  child: _mode == GameMode.image
                      ? TileImage(
                          image: image,
                          number: tileNumber,
                          gridSize: gridSize,
                        )
                      : TileSimple(
                          number: tileNumber,
                          gridSize: gridSize,
                        ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

class TileImage extends StatelessWidget {
  final Image image;
  final int number;
  final int gridSize;

  const TileImage({
    super.key,
    required this.image,
    required this.number,
    required this.gridSize,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.width;
        final tileSize = size / gridSize;
        final row = (number - 1) ~/ gridSize;
        final col = (number - 1) % gridSize;

        return ClipRect(
          child: Stack(
            children: [
              Positioned(
                top: -row * tileSize,
                left: -col * tileSize,
                child: SizedBox(
                  width: size,
                  height: size,
                  child: image,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class TileSimple extends StatelessWidget {
  final int number;
  final int gridSize;

  const TileSimple({
    super.key,
    required this.number,
    required this.gridSize,
  });

  static const List<Color> colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.pink,
    Colors.brown,
    Colors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    final letter = String.fromCharCode(64 + number); // 1 -> A, 2 -> B...
    return Container(
      margin: const EdgeInsets.all(2),
      color: colors[(number - 1) % colors.length],
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}