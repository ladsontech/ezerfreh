import 'package:flutter/material.dart';

class RiderScreen extends StatelessWidget {
  const RiderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Screen'),
      ),
      body: const Center(
        child: Text('Welcome, Rider!'),
      ),
    );
  }
}
