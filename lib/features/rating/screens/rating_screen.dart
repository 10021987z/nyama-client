import 'package:flutter/material.dart';

/// Stub Phase 1 — sera implémenté en Phase 2 (notation post-livraison).
class RatingScreen extends StatelessWidget {
  final String orderId;
  const RatingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Noter la commande')),
      body: Center(
        child: Text('Notation commande $orderId — bientôt disponible'),
      ),
    );
  }
}
