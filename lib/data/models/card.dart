class Card {
  const Card({
    required this.id,
    required this.holderName,
    required this.label,
    required this.maskedNumber,
    required this.bookedBalance,
    required this.currency,
    required this.gradientColors,
    required this.iban,
    double? availableBalance,
    this.isPrimary = false,
  }) : availableBalance = availableBalance ?? bookedBalance;

  final String id;
  final String holderName;
  final String label;
  final String maskedNumber;
  final double bookedBalance;
  final double availableBalance;
  final String currency;
  final List<int> gradientColors;
  final String iban;
  final bool isPrimary;
  double get balance => availableBalance;

  Card copyWith({
    String? id,
    String? holderName,
    String? label,
    String? maskedNumber,
    double? bookedBalance,
    double? availableBalance,
    String? currency,
    List<int>? gradientColors,
    String? iban,
    bool? isPrimary,
  }) {
    return Card(
      id: id ?? this.id,
      holderName: holderName ?? this.holderName,
      label: label ?? this.label,
      maskedNumber: maskedNumber ?? this.maskedNumber,
      bookedBalance: bookedBalance ?? this.bookedBalance,
      availableBalance: availableBalance ?? this.availableBalance,
      currency: currency ?? this.currency,
      gradientColors: gradientColors ?? this.gradientColors,
      iban: iban ?? this.iban,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}
