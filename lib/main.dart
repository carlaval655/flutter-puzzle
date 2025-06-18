import 'package:flutter/material.dart';
import 'package:puzzle_game/screens/home.dart'; // Asegúrate de que este archivo exista

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rompekokos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Home(),
      debugShowCheckedModeBanner: false,
    );
  }
}