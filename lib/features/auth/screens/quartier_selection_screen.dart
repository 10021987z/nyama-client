import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Stub Phase 1 — sera implémenté en Phase 2 (sélection quartier Douala/Yaoundé).
class QuartierSelectionScreen extends StatelessWidget {
  const QuartierSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choisis ton quartier')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Sélection du quartier — bientôt disponible'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Continuer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
