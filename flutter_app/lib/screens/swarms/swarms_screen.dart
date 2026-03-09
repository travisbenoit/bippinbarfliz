import 'package:flutter/material.dart';

class SwarmsScreen extends StatelessWidget {
  const SwarmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swarms'),
      ),
      body: const Center(
        child: Text('Group meetups coming soon'),
      ),
    );
  }
}
