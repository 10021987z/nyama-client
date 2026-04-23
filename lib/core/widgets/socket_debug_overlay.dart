import 'package:flutter/material.dart';
import '../network/socket_service.dart';
import '../storage/secure_storage.dart';

/// Bandeau fixe en bas d'écran qui affiche l'état temps-réel du socket.io.
/// Tap → dialog détaillé. Appui long → force SocketService.connect() avec le
/// token stocké (test manuel pour isoler un bug d'intégration auth).
class SocketDebugOverlay extends StatelessWidget {
  const SocketDebugOverlay({super.key});

  static const String _role = 'CLIENT';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SocketDebugInfo>(
      valueListenable: SocketService.debug,
      builder: (context, info, _) {
        final color = _colorFor(info.state);
        final label = _labelFor(info);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showDetails(context, info),
            onLongPress: () => _forceConnect(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.info_outline,
                      size: 12, color: Colors.white70),
                ],
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

  Future<void> _forceConnect(BuildContext context) async {
    // ignore: avoid_print
    print('[SocketDebugOverlay] 🔌 LONG PRESS — forcing connect()');
    final token = await SecureStorage.getAccessToken();
    final userId = await SecureStorage.getUserId();
    final preview =
        (token != null && token.length >= 20) ? token.substring(0, 20) : token;
    // ignore: avoid_print
    print(
      '[SocketDebugOverlay] token=$preview... userId=$userId role=$_role',
    );
    if (!context.mounted) return;
    if (token == null || token.isEmpty) {
      // ignore: avoid_print
      print('[SocketDebugOverlay] ❌ no token in storage — login d\'abord');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pas de token — connecte-toi d\'abord'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Force connect() avec token stocké…'),
        backgroundColor: Color(0xFF1565C0),
        duration: Duration(seconds: 2),
      ),
    );
    await SocketService.instance.connect(
      token,
      userId: userId,
      role: _role,
    );
  }
}
