import 'package:flutter/material.dart';
// Asegúrate de que este archivo exista
import 'package:puzzle_game/screens/menu_screen.dart';
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
      home: const MenuScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}