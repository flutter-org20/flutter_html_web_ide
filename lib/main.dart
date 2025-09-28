import 'package:flutter/material.dart';
import 'package:flutter_html_web_ide/ide_screen.dart';

void main() {
  runApp(const FlutterHtmlWebIDE());
}

class FlutterHtmlWebIDE extends StatelessWidget {
  const FlutterHtmlWebIDE({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HTML Web IDE',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const IDEScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
