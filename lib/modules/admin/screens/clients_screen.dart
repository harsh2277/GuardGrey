import 'package:flutter/material.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Clients',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
