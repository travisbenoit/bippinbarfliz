import 'package:flutter/material.dart';

class CreateSwarmScreen extends StatelessWidget {
  const CreateSwarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Swarm'),
      ),
      body: const Center(
        child: Text('Create a new group meetup'),
      ),
    );
  }
}
