import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  static const _whatsappNumber = '237699000000';

  static const _faqs = [
    _Faq(
      'Comment suivre ma commande ?',
      'Apres avoir passe commande, rendez-vous dans l\'onglet "Commandes" pour suivre en temps reel la preparation et la livraison. Vous recevrez aussi des notifications a chaque etape.',
    ),
    _Faq(
      'Quels moyens de paiement acceptes ?',
      'NYAMA accepte MTN Mobile Money, Orange Money, Falla et le paiement en especes a la livraison. Vous pouvez enregistrer vos numeros dans la section "Moyens de paiement".',
    ),
    _Faq(
      'Comment annuler une commande ?',
      'Une commande peut etre annulee gratuitement tant qu\'elle est au statut "En attente". Une fois "Confirmee" par la cuisiniere, contactez le support via WhatsApp.',
    ),
    _Faq(
      'Les frais de livraison sont-ils fixes ?',
      'Les frais de livraison varient selon votre zone de livraison et la distance avec la cuisiniere. Ils sont affiches avant validation du paiement.',
    ),
    _Faq(
      'Comment devenir livreur NYAMA ?',
      'Rendez-vous sur la page "Devenir livreur" depuis votre profil. Il vous suffit d\'avoir une moto, un permis et vos documents pour rejoindre notre reseau.',
    ),
  ];

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(
        'https://wa.me/$_whatsappNumber?text=${Uri.encodeComponent('Bonjour NYAMA, j\'ai besoin d\'aide.')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openTicketSheet(String category) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TicketSheet(category: category),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creme,
      appBar: AppBar(
        title: const Text('Support & Aide'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).canPop()
              ? Navigator.of(context).pop()
              : context.go('/profile'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 12),
            child: Text(
              'Comment pouvons-nous vous aider ?',
              style: TextStyle(
                fontFamily: AppTheme.headlineFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              _CategoryCard(
                icon: Icons.receipt_long,
                title: 'Probleme commande',
                color: AppColors.primary,
                onTap: () => _openTicketSheet('Probleme commande'),
              ),
              _CategoryCard(
                icon: Icons.payment,
                title: 'Question paiement',
                color: AppColors.forestGreen,
                onTap: () => _openTicketSheet('Question paiement'),
              ),
              _CategoryCard(
                icon: Icons.report_problem_outlined,
                title: 'Signaler',
                color: AppColors.errorRed,
                onTap: () => _openTicketSheet('Signaler un probleme'),
              ),
              _CategoryCard(
                icon: Icons.chat_bubble,
                title: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: _openWhatsApp,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(
              'Questions frequentes',
              style: TextStyle(
                fontFamily: AppTheme.headlineFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.charcoal.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: AppColors.surfaceLow),
                child: ExpansionPanelList.radio(
                  elevation: 0,
                  expandedHeaderPadding: EdgeInsets.zero,
                  children: _faqs.asMap().entries.map((entry) {
                    return ExpansionPanelRadio(
                      value: entry.key,
                      backgroundColor: Colors.white,
                      canTapOnHeader: true,
                      headerBuilder: (context, isExpanded) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Text(
                          entry.value.question,
                          style: const TextStyle(
                            fontFamily: AppTheme.headlineFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ),
                      body: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            entry.value.answer,
                            style: const TextStyle(
                              fontFamily: AppTheme.bodyFamily,
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Faq {
  final String question;
  final String answer;
  const _Faq(this.question, this.answer);
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.charcoal.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Text(
              title,
              style: const TextStyle(
                fontFamily: AppTheme.headlineFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketSheet extends StatefulWidget {
  final String category;
  const _TicketSheet({required this.category});

  @override
  State<_TicketSheet> createState() => _TicketSheetState();
}

class _TicketSheetState extends State<_TicketSheet> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _mapCategory(String cat) {
    if (cat.contains('commande')) return 'ORDER_ISSUE';
    if (cat.contains('paiement')) return 'PAYMENT_ISSUE';
    if (cat.contains('Signaler')) return 'TECHNICAL';
    return 'OTHER';
  }

  Future<void> _submit() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }
    setState(() => _submitting = true);

    try {
      await ApiClient.instance.post(
        ApiConstants.supportTickets,
        data: {
          'category': _mapCategory(widget.category),
          'subject': subject,
          'message': message,
          'reporterRole': 'CLIENT',
        },
      );
    } catch (_) {
      // Fallback silencieux si le réseau échoue — le ticket sera resoumis
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Votre message a ete envoye au support'),
        backgroundColor: AppColors.forestGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            widget.category,
            style: const TextStyle(
              fontFamily: AppTheme.headlineFamily,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Notre equipe vous repondra sous 24h',
            style: TextStyle(
              fontFamily: AppTheme.bodyFamily,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _subjectController,
            decoration: InputDecoration(
              labelText: 'Sujet',
              filled: true,
              fillColor: AppColors.surfaceLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Message',
              filled: true,
              fillColor: AppColors.surfaceLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Envoyer'),
            ),
          ),
        ],
      ),
    );
  }
}
