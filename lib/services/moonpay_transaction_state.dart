class MoonPayTransactionState {
  final bool isMoonPay;
  final String status;
  final String transactionId;

  const MoonPayTransactionState({
    required this.isMoonPay,
    required this.status,
    required this.transactionId,
  });

  bool get isPending => status == 'pending' || status == 'waitingForPayment';

  bool get isCompleted =>
      status == 'completed' || status == 'pending' || status == 'success';
}
