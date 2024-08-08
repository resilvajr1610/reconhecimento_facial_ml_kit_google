import 'package:flutter/material.dart';
import 'package:foto_rosto_automatica/pegarfoto.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pegar Foto IA',
      home: PegarFoto(),
    );
  }
}
