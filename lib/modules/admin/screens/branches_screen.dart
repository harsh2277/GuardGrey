import 'package:flutter/material.dart';

class BranchesScreen extends StatelessWidget {
  const BranchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Branches')),
      body: Center(
        child: Text(
          'Branches',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
