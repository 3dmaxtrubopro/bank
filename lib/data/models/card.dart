class Card {
  const Card({
    required this.id,
    required this.holderName,
    required this.label,
    required this.maskedNumber,
    required this.balance,
    required this.currency,
    required this.gradientColors,
    required this.iban,
    this.isPrimary = false,
  });

  final String id;
  final String holderName;
  final String label;
  final String maskedNumber;
  final double balance;
  final String currency;
  final List<int> gradientColors;
  final String iban;
  final bool isPrimary;
}
