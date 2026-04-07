import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_theme.dart';

class QuartierSelectionScreen extends StatefulWidget {
  const QuartierSelectionScreen({super.key});

  @override
  State<QuartierSelectionScreen> createState() =>
      _QuartierSelectionScreenState();
}

class _Quartier {
  final String name;
  final String area;
  const _Quartier(this.name, this.area);
}

class _QuartierSelectionScreenState extends State<QuartierSelectionScreen> {
  static const _cities = ['Douala', 'Yaoundé', 'Kribi'];

  static const Map<String, List<_Quartier>> _byCity = {
    'Douala': [
      _Quartier('Akwa', 'Douala 1er'),
      _Quartier('Bonapriso', 'Douala 1er'),
      _Quartier('Deido', 'Douala 1er'),
      _Quartier('Bonanjo', 'Douala 1er'),
      _Quartier('Ndokotti', 'Douala 3e'),
      _Quartier('Bali', 'Douala 1er'),
      _Quartier('Bonaberi', 'Douala 4e'),
      _Quartier('New Bell', 'Douala 2e'),
    ],
    'Yaoundé': [
      _Quartier('Bastos', 'Yaoundé 1er'),
      _Quartier('Mvan', 'Yaoundé 3e'),
      _Quartier('Biyem-Assi', 'Yaoundé 6e'),
      _Quartier('Nsimeyong', 'Yaoundé 3e'),
      _Quartier('Mimboman', 'Yaoundé 4e'),
      _Quartier('Essos', 'Yaoundé 4e'),
    ],
    'Kribi': [
      _Quartier('Centre-ville', 'Kribi'),
      _Quartier('Afan-Mabe', 'Kribi'),
    ],
  };

  String _city = 'Douala';
  String? _quartier;

  Future<void> _confirm() async {
    if (_quartier == null) return;
    await SecureStorage.saveQuartier(_city, _quartier!);
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final quartiers = _byCity[_city] ?? const [];

    return Scaffold(
      backgroundColor: AppColors.creme,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/onboarding/otp'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceLow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: AppColors.charcoal, size: 20),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on,
                            size: 56, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'Ton quartier',
                        style: TextStyle(
                          fontFamily: AppTheme.headlineFamily,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'On livre où exactement ?',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── City selector ─────────────────────────────
                    Row(
                      children: _cities.map((c) {
                        final active = c == _city;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _city = c;
                              _quartier = null;
                            }),
                            child: Container(
                              margin: EdgeInsets.only(
                                  right: c == _cities.last ? 0 : 8),
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.surfaceLow,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                c,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: active
                                      ? Colors.white
                                      : AppColors.charcoal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // ── Grid quartiers ────────────────────────────
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: quartiers.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.55,
                      ),
                      itemBuilder: (_, i) {
                        final q = quartiers[i];
                        final selected = q.name == _quartier;
                        return GestureDetector(
                          onTap: () => setState(() => _quartier = q.name),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Icon(Icons.home_filled,
                                        color: AppColors.primary, size: 22),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          q.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.charcoal,
                                          ),
                                        ),
                                        Text(
                                          q.area,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (selected)
                                  const Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Icon(Icons.check_circle,
                                        color: AppColors.primary, size: 20),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── CTA ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _quartier == null ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    disabledBackgroundColor:
                        AppColors.forestGreen.withValues(alpha: 0.4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "C'est parti !",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
