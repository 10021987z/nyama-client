import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

/// Écran 1.8 — Notation post-livraison NYAMA.
class RatingScreen extends StatefulWidget {
  final String orderId;
  const RatingScreen({super.key, required this.orderId});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  static const Color _waGreen = Color(0xFF25D366);
  static const List<String> _ratingLabels = [
    'Bof',
    'Moyen',
    'Bien',
    'Excellent',
    'Incroyable !',
  ];
  static const List<String> _tags = [
    'Livraison rapide',
    'Portion généreuse',
    'Très épicé',
    'C\'était chaud',
  ];

  int _foodRating = 0;
  int _riderRating = 0;
  final Set<String> _selectedTags = {};
  final TextEditingController _commentCtrl = TextEditingController();
  int _tipIndex = 1; // 0=none, 1=200, 2=500

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

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Merci pour votre avis !')),
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/orders');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creme,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(),
                    const SizedBox(height: 24),
                    const Text(
                      'Le goût était comment ?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Votre avis aide nos chefs à s\'améliorer.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildFoodStars(),
                    const SizedBox(height: 20),
                    _buildTagChips(),
                    const SizedBox(height: 24),
                    _buildRiderCard(),
                    const SizedBox(height: 24),
                    const Text(
                      'Un mot pour la cuisine ?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildCommentBox(),
                    const SizedBox(height: 24),
                    const Text(
                      'Pourboire pour Kevin ?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTipRow(),
                    const SizedBox(height: 24),
                    _buildSendButton(),
                    const SizedBox(height: 12),
                    _buildWhatsAppButton(),
                    const SizedBox(height: 14),
                    Center(
                      child: TextButton(
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go('/orders'),
                        child: const Text(
                          'Peut-être plus tard',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            key: const Key('rating_close_button'),
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/orders'),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'NYAMA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.forestGreen, Color(0xFF2D6B4F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.restaurant_menu,
              size: 80,
              color: Colors.white24,
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'ORDER #${widget.orderId}',
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodStars() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final filled = i < _foodRating;
            return GestureDetector(
              key: Key('food_star_$i'),
              onTap: () => setState(() => _foodRating = i + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 40,
                  color: AppColors.gold,
                ),
              ),
            );
          }),
        ),
        if (_foodRating > 0) ...[
          const SizedBox(height: 6),
          Text(
            _ratingLabels[_foodRating - 1],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTagChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tags.map((t) {
        final active = _selectedTags.contains(t);
        return GestureDetector(
          key: Key('tag_${t.replaceAll(' ', '_')}'),
          onTap: () => _toggleTag(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(20),
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRiderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: const Text(
                  'K',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kevin',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Ton livreur',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Et la livraison ?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (i) {
              final filled = i < _riderRating;
              return GestureDetector(
                key: Key('rider_star_$i'),
                onTap: () => setState(() => _riderRating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 28,
                    color: AppColors.gold,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentBox() {
    return TextField(
      controller: _commentCtrl,
      maxLines: 4,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Laisse un petit mot à la cuisinière...',
        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
        filled: true,
        fillColor: AppColors.surfaceLow,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildTipRow() {
    Widget tip(int idx, String label, {bool mono = false}) {
      final active = _tipIndex == idx;
      return Expanded(
        child: GestureDetector(
          key: Key('tip_$idx'),
          onTap: () => setState(() => _tipIndex = idx),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? AppColors.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: mono ? 'SpaceMono' : null,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tip(0, 'Pas cette fois'),
        const SizedBox(width: 8),
        tip(1, '200 FCFA', mono: true),
        const SizedBox(width: 8),
        tip(2, '500 FCFA', mono: true),
      ],
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        key: const Key('rating_submit_button'),
        onPressed: _foodRating > 0 ? _submit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              AppColors.forestGreen.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Envoyer mon avis',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            SizedBox(width: 8),
            Icon(Icons.play_arrow_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Partage WhatsApp bientôt dispo')),
          );
        },
        style: TextButton.styleFrom(
          backgroundColor: _waGreen.withValues(alpha: 0.1),
          foregroundColor: _waGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.chat_bubble, size: 18),
        label: const Text(
          'Partager sur WhatsApp',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
