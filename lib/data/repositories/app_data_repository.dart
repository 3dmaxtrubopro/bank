import '../../core/constants.dart';
import '../models/card.dart';
import '../models/transaction.dart';

class AppDataRepository {
  AppDataRepository._();

  static final AppDataRepository instance = AppDataRepository._();

  final List<Card> _cards = const <Card>[
    Card(
      id: 'primary',
      holderName: 'Alex Morgan',
      label: 'UBS Platinum',
      maskedNumber: '**** 1847',
      balance: 128450.90,
      currency: AppConstants.defaultCurrency,
      gradientColors: <int>[0xFF191919, 0xFF3A2E1C],
      iban: 'CH93 0076 2011 6238 5295 7',
      isPrimary: true,
    ),
    Card(
      id: 'travel',
      holderName: 'Alex Morgan',
      label: 'UBS Travel',
      maskedNumber: '**** 6721',
      balance: 9420.20,
      currency: AppConstants.defaultCurrency,
      gradientColors: <int>[0xFF20404F, 0xFF6B8E9B],
      iban: 'CH12 0023 8756 9104 0083 4',
    ),
    Card(
      id: 'reserve',
      holderName: 'Alex Morgan',
      label: 'UBS Reserve',
      maskedNumber: '**** 9024',
      balance: 245800.00,
      currency: AppConstants.defaultCurrency,
      gradientColors: <int>[0xFF5B4A35, 0xFFB8A06A],
      iban: 'CH44 0900 0000 8756 3112 5',
    ),
  ];

  final List<Transaction> _transactions = <Transaction>[
    Transaction(
      id: 't1',
      cardId: 'primary',
      title: 'Wealth management fee',
      subtitle: 'Advisory services',
      amount: -1250.00,
      currency: AppConstants.defaultCurrency,
      date: DateTime(2026, 4, 7, 14, 20),
    ),
    Transaction(
      id: 't2',
      cardId: 'primary',
      title: 'Salary transfer',
      subtitle: 'UBS payroll',
      amount: 8400.00,
      currency: AppConstants.defaultCurrency,
      date: DateTime(2026, 4, 6, 9, 10),
    ),
    Transaction(
      id: 't3',
      cardId: 'travel',
      title: 'Travel expenses',
      subtitle: 'Zurich airport lounge',
      amount: -320.45,
      currency: AppConstants.defaultCurrency,
      date: DateTime(2026, 4, 2, 18, 40),
    ),
    Transaction(
      id: 't4',
      cardId: 'reserve',
      title: 'Portfolio dividend',
      subtitle: 'Equity income',
      amount: 186.30,
      currency: AppConstants.defaultCurrency,
      date: DateTime(2026, 3, 31, 11, 5),
    ),
    Transaction(
      id: 't5',
      cardId: 'primary',
      title: 'Private client dinner',
      subtitle: 'La Reserve Geneve',
      amount: -184.90,
      currency: AppConstants.defaultCurrency,
      date: DateTime(2026, 3, 31, 20, 15),
    ),
    Transaction(
      id: 't6',
      cardId: 'travel',
      title: 'Hotel refund',
      subtitle: 'Zurich West Hotel',
      amount: 240.00,
      currency: AppConstants.defaultCurrency,
      date: DateTime(2026, 3, 29, 16, 45),
    ),
  ];

  Future<List<Card>> getCards() async {
    await Future<void>.delayed(AppConstants.apiDelay);
    return List<Card>.unmodifiable(_cards);
  }

  Future<Card?> getCardById(String cardId) async {
    await Future<void>.delayed(AppConstants.apiDelay);
    for (final Card card in _cards) {
      if (card.id == cardId) {
        return card;
      }
    }
    return null;
  }

  Future<List<Transaction>> getTransactions() async {
    await Future<void>.delayed(AppConstants.apiDelay);
    return List<Transaction>.unmodifiable(_sortedTransactions(_transactions));
  }

  Future<List<Transaction>> getTransactionsByCardId(String cardId) async {
    await Future<void>.delayed(AppConstants.apiDelay);
    final List<Transaction> filtered = _transactions
        .where((Transaction transaction) => transaction.cardId == cardId)
        .toList(growable: false);
    return List<Transaction>.unmodifiable(_sortedTransactions(filtered));
  }

  Future<void> addTransaction(Transaction transaction) async {
    await Future<void>.delayed(AppConstants.apiDelay);
    _transactions.insert(0, transaction);
  }

  List<Transaction> _sortedTransactions(List<Transaction> items) {
    return List<Transaction>.from(items)
      ..sort(
        (Transaction left, Transaction right) => right.date.compareTo(left.date),
      );
  }
}
