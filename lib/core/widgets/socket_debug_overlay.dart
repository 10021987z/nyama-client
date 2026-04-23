import 'package:flutter/material.dart';
import '../network/socket_service.dart';

/// Bandeau fixe en bas d'écran qui affiche l'état temps-réel du socket.io.
/// Tap → dialog détaillé avec url, token preview, dernière erreur, dernier event.
class SocketDebugOverlay extends StatelessWidget {
  const SocketDebugOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SocketDebugInfo>(
      valueListenable: SocketService.debug,
      builder: (context, info, _) {
        final color = _colorFor(info.state);
        final label = _labelFor(info);
        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showDetails(context, info),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                color: color,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.info_outline,
                        size: 14, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Color _colorFor(String state) {
    switch (state) {
      case 'connected':
        return const Color(0xFF2E7D32); // vert
      case 'connecting':
        return const Color(0xFFEF6C00); // orange
      case 'error':
        return const Color(0xFFC62828); // rouge
      case 'idle':
      default:
        return const Color(0xFF616161); // gris
    }
  }

  static String _labelFor(SocketDebugInfo info) {
    switch (info.state) {
      case 'connected':
        final sid = info.sid ?? '?';
        final short = sid.length > 8 ? sid.substring(0, 8) : sid;
        return '🟢 Socket OK · sid=$short';
      case 'error':
        final err = info.lastError ?? 'unknown';
        return '🔴 ${_shortError(err)} · erreurs=${info.errorCount}';
      case 'connecting':
        return '🟡 Connecting (tentative ${info.connectCallCount})';
      case 'idle':
      default:
        return '⚪️ Socket idle (pas encore connecté)';
    }
  }

  static String _shortError(String err) {
    // garde les 80 premiers chars pour tenir sur une ligne
    return err.length > 80 ? '${err.substring(0, 80)}…' : err;
  }

  void _showDetails(BuildContext context, SocketDebugInfo info) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Socket.IO — debug'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _row('État', info.state),
                _row('URL', info.url.isEmpty ? '(non défini)' : info.url),
                _row('Token', info.tokenPreview.isEmpty
                    ? '(aucun)'
                    : '${info.tokenPreview}…'),
                _row('SID', info.sid ?? '(aucun)'),
                _row('Dernier event', info.lastEvent ?? '(aucun)'),
                _row('Tentatives connect()',
                    info.connectCallCount.toString()),
                _row('Erreurs', info.errorCount.toString()),
                const SizedBox(height: 8),
                const Text('Dernière erreur :',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                SelectableText(
                  info.lastError ?? '(aucune)',
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
