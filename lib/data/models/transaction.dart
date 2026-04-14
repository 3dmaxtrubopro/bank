enum TransactionStatus { booked, pending }

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
    this.status = TransactionStatus.booked,
  });

  final String id;
  final String cardId;
  final String title;
  final String subtitle;
  final double amount;
  final String currency;
  final DateTime date;
  final String emoji;
  final TransactionStatus status;

  Transaction copyWith({
    String? id,
    String? cardId,
    String? title,
    String? subtitle,
    double? amount,
    String? currency,
    DateTime? date,
    String? emoji,
    TransactionStatus? status,
  }) {
    return Transaction(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      emoji: emoji ?? this.emoji,
      status: status ?? this.status,
    );
  }
}
