import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_gate.dart';
import '../../orders/data/orders_repository.dart';
import '../../orders/providers/orders_provider.dart';

/// Écran 1.8 — Notation post-livraison NYAMA.
///
/// Cet écran est ouvert automatiquement 2s après l'event DELIVERED par
/// `OrderTrackingScreen._navigateToRating()`.
///
/// Spec :
///   - Titre : « Merci ! Votre commande est arrivée »
///   - Avatar livreur + nom (depuis `order.delivery.riderName`)
///   - 5 étoiles cliquables — REQUIS pour activer le bouton Envoyer
///   - Zone de texte optionnelle « Laisser un commentaire »
///   - 3 bulles tags rapides : Rapide / Sympathique / Professionnel
///   - Bouton « Envoyer » → POST /orders/:id/rating { stars, comment, tags }
///     → bref écran de remerciement → retour /home
///   - Bouton « Passer » en petit en bas
class RatingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const RatingScreen({super.key, required this.orderId});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  static const List<String> _ratingLabels = [
    'Décevant',
    'Bof',
    'Bien',
    'Très bien',
    'Parfait !',
  ];
  static const List<String> _quickTags = [
    'Rapide',
    'Sympathique',
    'Professionnel',
  ];

  int _stars = 0;
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
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci de noter votre livreur.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await OrdersRepository().submitRating(
        orderId: widget.orderId,
        stars: _stars,
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
        SnackBar(content: Text('Erreur : ${e.toString()}')),
      );
      setState(() => _submitting = false);
    }
  }

  void _skip() {
    if (!mounted) return;
    context.go('/home');
  }

  /// Affiche un dialog "Merci !" non bloquant pendant 1.5s puis retour /home.
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
                'Merci pour votre avis !',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.charcoal,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'À très bientôt sur NYAMA.',
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
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).maybePop();
      context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Hydrate le rider depuis le détail commande pour afficher nom + photo.
    final asyncOrder = ref.watch(orderDetailProvider(widget.orderId));
    final rider = asyncOrder.value?.delivery;
    final riderName =
        (rider?.riderName ?? '').isNotEmpty ? rider!.riderName! : 'Kevin';
    final riderPhoto = rider?.riderPhotoUrl;
    final initial =
        riderName.isNotEmpty ? riderName[0].toUpperCase() : 'K';

    return Scaffold(
      backgroundColor: AppColors.creme,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Merci ! Votre commande est arrivée',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.charcoal,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Comment s\'est passée la livraison avec $riderName ?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildRiderHeader(riderName, riderPhoto, initial),
                    const SizedBox(height: 24),
                    _buildStars(),
                    const SizedBox(height: 22),
                    _buildQuickTags(),
                    const SizedBox(height: 24),
                    _buildCommentBox(),
                    const SizedBox(height: 28),
                    _buildSendButton(),
                    const SizedBox(height: 8),
                    _buildSkipButton(),
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
            onPressed: _skip,
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

  Widget _buildRiderHeader(String name, String? photoUrl, String initial) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2.5),
          ),
          child: CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: (photoUrl ?? '').isNotEmpty
                ? NetworkImage(photoUrl!)
                : null,
            child: (photoUrl ?? '').isEmpty
                ? Text(
                    initial,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Votre livreur',
          style: TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStars() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final filled = i < _stars;
            return GestureDetector(
              key: Key('rider_star_$i'),
              onTap: () => setState(() => _stars = i + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 44,
                  color: AppColors.gold,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 18,
          child: _stars > 0
              ? Text(
                  _ratingLabels[_stars - 1],
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildQuickTags() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: _quickTags.map((t) {
        final active = _selectedTags.contains(t);
        return GestureDetector(
          key: Key('tag_${t.toLowerCase()}'),
          onTap: () => _toggleTag(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: active
                    ? AppColors.primary
                    : AppColors.outlineVariant.withValues(alpha: 0.5),
                width: active ? 1.5 : 1,
              ),
            ),
            child: Text(
              t,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.primary : AppColors.charcoal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCommentBox() {
    return TextField(
      controller: _commentCtrl,
      maxLines: 3,
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
    final enabled = _stars > 0 && !_submitting;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        key: const Key('rating_submit_button'),
        onPressed: enabled ? _submit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              AppColors.forestGreen.withValues(alpha: 0.4),
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

  Widget _buildSkipButton() {
    return TextButton(
      key: const Key('rating_skip_button'),
      onPressed: _skip,
      child: const Text(
        'Passer',
        style: TextStyle(
          fontFamily: 'NunitoSans',
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
