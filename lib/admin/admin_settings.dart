import 'package:flutter/material.dart';

class AdminSettings extends StatelessWidget {
  const AdminSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Settings'),
      ),
      body: const Center(
        child: Text('Admin Settings Page'),
      ),
    );
  }
}