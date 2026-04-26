import 'package:flutter/material.dart';

class SitesScreen extends StatelessWidget {
  const SitesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Sites',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
