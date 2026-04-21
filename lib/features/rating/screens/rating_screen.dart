import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_gate.dart';
import '../../orders/data/orders_repository.dart';
import '../../orders/providers/orders_provider.dart';

/// Écran 1.8 — Notation post-livraison NYAMA.
///
/// 3 sections OBLIGATOIRES (bouton « Envoyer » désactivé tant que les 3 étoiles
/// ne sont pas remplies) :
///   1. Note livreur     : `${riderName}`      + tags rapides multi-sélection
///   2. Note plat        : `${restaurantName}` (nom cuisinière / restaurant)
///   3. Note app NYAMA
///
/// + Commentaire optionnel (maxLines 3, maxLength 300).
/// + Bouton unique « Envoyer » → POST /orders/:id/rating.
/// + Après succès : écran de remerciement 2s puis `context.go('/home')`.
class RatingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const RatingScreen({super.key, required this.orderId});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  static const List<String> _quickTags = [
    'Rapide',
    'Sympathique',
    'Professionnel',
    'Ponctuel',
  ];

  int _riderStars = 0;
  int _restaurantStars = 0;
  int _appStars = 0;
  final Set<String> _selectedTags = {};
  final TextEditingController _commentCtrl = TextEditingController();
  bool _submitting = false;
  bool _thanksShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await AuthGate.ensureAuthenticated(context);
      if (!ok && mounted) {
        context.pop();
      }
    });
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _riderStars > 0 &&
      _restaurantStars > 0 &&
      _appStars > 0 &&
      !_submitting;

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      await OrdersRepository().submitRating(
        orderId: widget.orderId,
        riderStars: _riderStars,
        restaurantStars: _restaurantStars,
        appStars: _appStars,
        comment: _commentCtrl.text.trim().isEmpty
            ? null
            : _commentCtrl.text.trim(),
        tags: _selectedTags.toList(),
      );
      if (!mounted) return;
      _showThanksAndGoHome();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${e.toString()}'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      setState(() => _submitting = false);
    }
  }

  /// Écran de remerciement non bloquant pendant 2s puis retour `/`.
  /// Idempotent : un re-appel ne déclenche pas un second dialog.
  void _showThanksAndGoHome() {
    if (_thanksShown) return;
    _thanksShown = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_rounded,
                  size: 56, color: AppColors.primary),
              SizedBox(height: 12),
              Text(
                'Merci !',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.charcoal,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Vos avis aident NYAMA.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).maybePop();
      context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Hydrate depuis le détail commande → rider + cuisinière.
    final asyncOrder = ref.watch(orderDetailProvider(widget.orderId));
    final order = asyncOrder.value;
    final rider = order?.delivery;
    final riderName = (rider?.riderName ?? '').isNotEmpty
        ? rider!.riderName!
        : 'Votre livreur';
    final restaurantName =
        (order?.cookName ?? '').isNotEmpty ? order!.cookName : 'Votre plat';

    return Scaffold(
      backgroundColor: AppColors.creme,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Votre commande est arrivée',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.charcoal,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Dites-nous ce que vous en avez pensé.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── 1. Note livreur ─────────────────────────────────
                    _SectionCard(
                      title: 'Votre livreur',
                      subtitle: riderName,
                      child: Column(
                        children: [
                          _StarsRow(
                            keyPrefix: 'rider',
                            value: _riderStars,
                            onChanged: (v) =>
                                setState(() => _riderStars = v),
                          ),
                          const SizedBox(height: 14),
                          _TagsRow(
                            tags: _quickTags,
                            selected: _selectedTags,
                            onToggle: _toggleTag,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── 2. Note plat / cuisinière ───────────────────────
                    _SectionCard(
                      title: 'Le plat',
                      subtitle: restaurantName,
                      child: _StarsRow(
                        keyPrefix: 'restaurant',
                        value: _restaurantStars,
                        onChanged: (v) =>
                            setState(() => _restaurantStars = v),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── 3. Note app NYAMA ───────────────────────────────
                    _SectionCard(
                      title: 'L’application',
                      subtitle: 'NYAMA',
                      child: _StarsRow(
                        keyPrefix: 'app',
                        value: _appStars,
                        onChanged: (v) => setState(() => _appStars = v),
                      ),
                    ),
                    const SizedBox(height: 18),

                    _buildCommentBox(),
                    const SizedBox(height: 24),

                    _buildSendButton(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            key: const Key('rating_close_button'),
            icon: const Icon(Icons.close, color: AppColors.charcoal),
            onPressed: () => context.go('/home'),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'NYAMA',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppColors.charcoal,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCommentBox() {
    return TextField(
      controller: _commentCtrl,
      maxLines: 3,
      maxLength: 300,
      style: const TextStyle(fontFamily: 'NunitoSans', fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Laisser un commentaire (optionnel)',
        hintStyle: const TextStyle(
          fontFamily: 'NunitoSans',
          color: AppColors.textTertiary,
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.surfaceWhite,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        key: const Key('rating_submit_button'),
        onPressed: _canSubmit ? _submit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              AppColors.forestGreen.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _submitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Text(
                'Envoyer',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

// ─── Sub-widgets ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _StarsRow extends StatelessWidget {
  final String keyPrefix;
  final int value;
  final ValueChanged<int> onChanged;

  const _StarsRow({
    required this.keyPrefix,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final filled = i < value;
        return GestureDetector(
          key: Key('${keyPrefix}_star_$i'),
          onTap: () => onChanged(i + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 38,
              color: AppColors.gold,
            ),
          ),
        );
      }),
    );
  }
}

class _TagsRow extends StatelessWidget {
  final List<String> tags;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _TagsRow({
    required this.tags,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: tags.map((t) {
        final active = selected.contains(t);
        return GestureDetector(
          key: Key('tag_${t.toLowerCase()}'),
          onTap: () => onToggle(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: active
                    ? AppColors.primary
                    : AppColors.outlineVariant.withValues(alpha: 0.4),
                width: active ? 1.5 : 1,
              ),
            ),
            child: Text(
              t,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.primary : AppColors.charcoal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
