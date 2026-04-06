import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class RiderSignupScreen extends StatefulWidget {
  const RiderSignupScreen({super.key});

  @override
  State<RiderSignupScreen> createState() => _RiderSignupScreenState();
}

class _RiderSignupScreenState extends State<RiderSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _vehicleType = 'moto';
  bool _acceptCgu = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ───────────────────────────────────────────────
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              color: AppColors.surfaceContainerLowest,
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20, color: AppColors.onSurface),
                      ),
                      const Spacer(),
                      Text(
                        'NYAMA',
                        style: TextStyle(fontFamily: 'Montserrat',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryVibrant.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'DEVENIR PARTENAIRE LIVREUR',
                      style: TextStyle(fontFamily: 'NunitoSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryVibrant,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),

                  // ── Hero Section ─────────────────────────────────────
                  Text(
                    'Soyez votre propre patron avec Nyama',
                    style: TextStyle(fontFamily: 'Montserrat',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Rejoignez notre réseau de livreurs et gagnez de l\'argent à votre rythme. Livrez des repas savoureux et faites la différence dans votre communauté.',
                    style: TextStyle(fontFamily: 'NunitoSans',
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // CTA Button
                  GestureDetector(
                    onTap: () {
                      Scrollable.ensureVisible(
                        _formKey.currentContext ?? context,
                        duration: const Duration(milliseconds: 400),
                      );
                    },
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Center(
                        child: Text(
                          'Commencer maintenant',
                          style: TextStyle(fontFamily: 'NunitoSans',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Active riders badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Plus de 500 livreurs actifs',
                        style: TextStyle(fontFamily: 'NunitoSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Earnings card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.payments_rounded,
                            color: AppColors.success, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          '150,000 FCFA / mois',
                          style: TextStyle(fontFamily: 'Montserrat',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Why Choose Section ───────────────────────────────
                  Text(
                    'Pourquoi choisir NYAMA ?',
                    style: TextStyle(fontFamily: 'Montserrat',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _FeatureRow(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Gains immédiats via MoMo',
                    subtitle:
                        'Recevez vos gains directement sur votre mobile money',
                  ),
                  _FeatureRow(
                    icon: Icons.schedule_rounded,
                    title: 'Horaires flexibles',
                    subtitle:
                        'Travaillez quand vous le souhaitez, à votre rythme',
                  ),
                  _FeatureRow(
                    icon: Icons.shield_rounded,
                    title: 'Support 24/7',
                    subtitle:
                        'Notre équipe est toujours là pour vous accompagner',
                  ),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '"C\'est le deal quand vous avez besoin, c\'est votre solution de réussite."',
                      style: TextStyle(fontFamily: 'Montserrat',
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: AppColors.primary,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Requirements Section ─────────────────────────────
                  Text(
                    'Ce qu\'il vous faut pour commencer',
                    style: TextStyle(fontFamily: 'Montserrat',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _RequirementStep(
                    number: '1',
                    title: 'Moto',
                    subtitle:
                        'Un deux-roues en bon état pour vos livraisons',
                  ),
                  _RequirementStep(
                    number: '2',
                    title: 'Smartphone',
                    subtitle:
                        'Un téléphone avec accès à Internet pour recevoir les commandes',
                  ),
                  _RequirementStep(
                    number: '3',
                    title: 'Pièce d\'identité',
                    subtitle:
                        'CNI ou passeport valide pour la vérification',
                  ),

                  const SizedBox(height: 36),

                  // ── Signup Form ──────────────────────────────────────
                  Text(
                    'Inscrivez-vous en 2 minutes',
                    style: TextStyle(fontFamily: 'Montserrat',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Name
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(fontFamily: 'NunitoSans',fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Nom complet',
                            labelStyle: TextStyle(fontFamily: 'NunitoSans',
                                fontSize: 14,
                                color: AppColors.textSecondary),
                            prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                                size: 20),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Veuillez saisir votre nom'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Phone
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(fontFamily: 'NunitoSans',fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Numéro de téléphone',
                            labelStyle: TextStyle(fontFamily: 'NunitoSans',
                                fontSize: 14,
                                color: AppColors.textSecondary),
                            hintText: '+237 6XX XXX XXX',
                            hintStyle: TextStyle(fontFamily: 'NunitoSans',
                                fontSize: 14,
                                color: AppColors.textTertiary),
                            prefixIcon: const Icon(
                                Icons.phone_outlined,
                                size: 20),
                          ),
                          validator: (v) => v == null || v.trim().length < 9
                              ? 'Numéro invalide'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Vehicle Type
                        DropdownButtonFormField<String>(
                          initialValue: _vehicleType,
                          style: TextStyle(fontFamily: 'NunitoSans',
                              fontSize: 14, color: AppColors.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Type de véhicule',
                            labelStyle: TextStyle(fontFamily: 'NunitoSans',
                                fontSize: 14,
                                color: AppColors.textSecondary),
                            prefixIcon: const Icon(
                                Icons.two_wheeler_rounded,
                                size: 20),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'moto',
                                child: Text('Moto')),
                            DropdownMenuItem(
                                value: 'velo',
                                child: Text('Vélo')),
                            DropdownMenuItem(
                                value: 'voiture',
                                child: Text('Voiture')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _vehicleType = v);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // CGU Checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _acceptCgu,
                                onChanged: (v) =>
                                    setState(() => _acceptCgu = v ?? false),
                                activeColor: AppColors.primaryVibrant,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _acceptCgu = !_acceptCgu),
                                child: Text(
                                  'J\'accepte les Conditions Générales d\'Utilisation et la Politique de Confidentialité de NYAMA.',
                                  style: TextStyle(fontFamily: 'NunitoSans',
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        GestureDetector(
                          onTap: _acceptCgu && !_isSubmitting
                              ? _submit
                              : null,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: _acceptCgu && !_isSubmitting
                                  ? AppColors.primaryGradient
                                  : null,
                              color: _acceptCgu && !_isSubmitting
                                  ? null
                                  : AppColors.textTertiary,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Center(
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Envoyer ma candidature',
                                          style: TextStyle(fontFamily: 'NunitoSans',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.white,
                                            size: 20),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Footer ───────────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'NYAMA',
                          style: TextStyle(fontFamily: 'Montserrat',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Delivering Tradition & Craft',
                          style: TextStyle(fontFamily: 'NunitoSans',
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _FooterLink(label: 'À propos'),
                            _FooterDot(),
                            _FooterLink(label: 'CGU'),
                            _FooterDot(),
                            _FooterLink(label: 'Contact'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptCgu) return;

    setState(() => _isSubmitting = true);

    // Simulate API call
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Candidature envoyée ! Nous vous contacterons bientôt.',
          style: TextStyle(fontFamily: 'NunitoSans',fontSize: 14, color: Colors.white),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ─── Feature Row ─────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryVibrant.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryVibrant, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontFamily: 'NunitoSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontFamily: 'NunitoSans',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Requirement Step ────────────────────────────────────────────────────

class _RequirementStep extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;

  const _RequirementStep({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primaryVibrant,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(fontFamily: 'NunitoSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontFamily: 'NunitoSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontFamily: 'NunitoSans',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Footer Helpers ──────────────────────────────────────────────────────

class _FooterLink extends StatelessWidget {
  final String label;

  const _FooterLink({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(fontFamily: 'NunitoSans',
        fontSize: 13,
        color: AppColors.primaryVibrant,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _FooterDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '·',
        style: TextStyle(fontFamily: 'NunitoSans',
          fontSize: 13,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
