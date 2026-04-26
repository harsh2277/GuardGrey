import 'package:flutter/material.dart';

class ManagersScreen extends StatelessWidget {
  const ManagersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Managers',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
