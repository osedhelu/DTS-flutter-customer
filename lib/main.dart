import 'package:flutter/material.dart';

void main() {
  runApp(const DtsCustomerApp());
}

class DtsCustomerApp extends StatelessWidget {
  const DtsCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DTS Cliente',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('DTS Cliente — iniciar con /fase-4'),
        ),
      ),
    );
  }
}
