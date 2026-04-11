class Transaction {
  const Transaction({
    required this.id,
    required this.cardId,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.currency,
    required this.date,
    this.emoji = '💳',
  });

  final String id;
  final String cardId;
  final String title;
  final String subtitle;
  final double amount;
  final String currency;
  final DateTime date;
  final String emoji;
}
