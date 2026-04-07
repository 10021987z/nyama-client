/// PaymentsRepository — version simulée Phase 4.
///
/// Le vrai NotchPay sera branché quand le module backend payments sera prêt.
/// En attendant, [initiatePayment] simule un succès après 2 secondes.
class PaymentInitResult {
  final bool success;
  final String transactionId;
  final String status; // 'paid' | 'failed' | 'pending'
  final String? message;

  const PaymentInitResult({
    required this.success,
    required this.transactionId,
    required this.status,
    this.message,
  });
}

class PaymentsRepository {
  /// Simule un appel POST /api/v1/payments/initiate.
  ///
  /// Paramètres tels que voulus par le brief :
  /// - [orderId] : commande créée juste avant via OrdersRepository.createOrder
  /// - [amount]  : montant total en XAF
  /// - [currency]: 'XAF'
  /// - [phone]   : numéro Mobile Money de l'utilisateur
  /// - [method]  : 'mtn_momo' | 'orange_money'
  Future<PaymentInitResult> initiatePayment({
    required String orderId,
    required int amount,
    required String currency,
    required String phone,
    required String method,
  }) async {
    // TODO(payments): brancher NotchPay quand le backend sera prêt.
    await Future.delayed(const Duration(seconds: 2));
    return PaymentInitResult(
      success: true,
      transactionId: 'SIMU-${DateTime.now().millisecondsSinceEpoch}',
      status: 'paid',
      message: 'Paiement simulé avec succès',
    );
  }
}
