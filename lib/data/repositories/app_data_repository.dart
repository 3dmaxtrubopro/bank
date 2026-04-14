import '../../core/constants.dart';
import '../models/card.dart';
import '../models/transaction.dart';

class AppDataRepository {
  AppDataRepository._();

  static final AppDataRepository instance = AppDataRepository._();

  final List<Card> _cards = <Card>[
    const Card(
      id: 'primary',
      holderName: 'Alex Morgan',
      label: 'PostFinance Platinum',
      maskedNumber: '**** 1847',
      bookedBalance: 128450.90,
      currency: AppConstants.defaultCurrency,
      gradientColors: <int>[0xFF191919, 0xFF3A2E1C],
      iban: 'CH93 0076 2011 6238 5295 7',
      isPrimary: true,
    ),
    const Card(
      id: 'travel',
      holderName: 'Alex Morgan',
      label: 'PostFinance Travel',
      maskedNumber: '**** 6721',
      bookedBalance: 9420.20,
      currency: AppConstants.defaultCurrency,
      gradientColors: <int>[0xFF20404F, 0xFF6B8E9B],
      iban: 'CH12 0023 8756 9104 0083 4',
    ),
    const Card(
      id: 'reserve',
      holderName: 'Alex Morgan',
      label: 'PostFinance Reserve',
      maskedNumber: '**** 9024',
      bookedBalance: 245800.00,
      currency: AppConstants.defaultCurrency,
      gradientColors: <int>[0xFF5B4A35, 0xFFB8A06A],
      iban: 'CH44 0900 0000 8756 3112 5',
    ),
  ];

  final List<Transaction> _transactions = <Transaction>[
    Transaction(
      id: 't1',
      cardId: 'primary',
      title: 'Envoi d’argent TWINT à +41768237835',
      subtitle: 'TWINT',
      amount: -3.00,
      currency: AppConstants.defaultCurrency,
      date: DateTime(2026, 4, 5, 13, 15),
      emoji: '🅣',
    ),
    Transaction(
      id: 't2',
      cardId: 'primary',
      title: 'Apple Pay Achat/service du 20.03.2026, kkiosk Delémont CFF',
      subtitle: 'KKIOSK DELÉMONT',
      amount: -7.05,
      currency: AppConstants.defaultCurrency,
      date: DateTime(2026, 3, 20, 12, 40),
      emoji: '',
    ),
    Transaction(
      id: 't3',
      cardId: 'primary',
      title: 'Apple Pay Achat/service du 20.03.2026, KIOSQUE ST MARCEL',
      subtitle: 'KIOSQUE ST MARCEL',
      amount: -10.60,
      currency: AppConstants.defaultCurrency,
      date: DateTime(2026, 3, 20, 12, 23),
      emoji: '🅚',
      status: TransactionStatus.pending,
    ),
    Transaction(
      id: 't4',
      cardId: 'primary',
      title: 'Apple Pay Achat/service du 20.03.2026, Alima Delémont',
      subtitle: 'ALIMA DELÉMONT',
      amount: -2.50,
      currency: AppConstants.defaultCurrency,
      date: DateTime(2026, 3, 20, 11, 52),
      emoji: '🛒',
    ),
    Transaction(
      id: 't5',
      cardId: 'primary',
      title: 'Apple Pay Achat/service du 20.03.2026, Le Bleu Lézard',
      subtitle: 'LE BLEU LÉZARD',
      amount: -23.90,
      currency: AppConstants.defaultCurrency,
      date: DateTime(2026, 3, 20, 10, 10),
      emoji: '🍽️',
    ),
    Transaction(
      id: 't6',
      cardId: 'primary',
      title: 'Apple Pay Achat/shopping en ligne du 19.03.2026, APPLE.COM/BILL',
      subtitle: 'APPLE.COM/BILL',
      amount: -8.60,
      currency: AppConstants.defaultCurrency,
      date: DateTime(2026, 3, 19, 17, 34),
      emoji: '',
    ),
    Transaction(
      id: 't7',
      cardId: 'primary',
      title: 'Apple Pay Achat/shopping en ligne du 18.03.2026, APPLE.COM/BILL',
      subtitle: 'APPLE.COM/BILL',
      amount: -1.00,
      currency: AppConstants.defaultCurrency,
      date: DateTime(2026, 3, 18, 8, 14),
      emoji: '',
    ),
    Transaction(
      id: 't8',
      cardId: 'reserve',
      title: 'Portfolio dividend',
      subtitle: 'Equity income',
      amount: 186.30,
      currency: AppConstants.defaultCurrency,
      date: DateTime(2026, 3, 31, 11, 5),
      emoji: '📈',
    ),
  ];

  Future<List<Card>> getCards() async {
    await Future<void>.delayed(AppConstants.apiDelay);
    _settlePendingTransactions();
    return List<Card>.unmodifiable(_cards);
  }

  Future<Card?> getCardById(String cardId) async {
    await Future<void>.delayed(AppConstants.apiDelay);
    _settlePendingTransactions();
    for (final Card card in _cards) {
      if (card.id == cardId) {
        return card;
      }
    }
    return null;
  }

  Future<List<Transaction>> getTransactions() async {
    await Future<void>.delayed(AppConstants.apiDelay);
    _settlePendingTransactions();
    return List<Transaction>.unmodifiable(
      _sortedTransactions(_withSettledStatuses(_transactions)),
    );
  }

  Future<List<Transaction>> getTransactionsByCardId(String cardId) async {
    await Future<void>.delayed(AppConstants.apiDelay);
    _settlePendingTransactions();
    final List<Transaction> filtered = _transactions
        .where((Transaction transaction) => transaction.cardId == cardId)
        .toList(growable: false);
    return List<Transaction>.unmodifiable(
      _sortedTransactions(_withSettledStatuses(filtered)),
    );
  }

  Future<Transaction?> getTransactionById(String transactionId) async {
    await Future<void>.delayed(AppConstants.apiDelay);
    _settlePendingTransactions();
    for (final Transaction transaction in _transactions) {
      if (transaction.id == transactionId) {
        return _applySettlementStatus(transaction);
      }
    }
    return null;
  }

  Future<void> addTransaction(Transaction transaction) async {
    await Future<void>.delayed(AppConstants.apiDelay);
    _transactions.insert(0, transaction);
    _applyCardBalanceDeltaOnCreate(transaction);
  }

  void _applyCardBalanceDeltaOnCreate(Transaction transaction) {
    _adjustCardBalance(
      cardId: transaction.cardId,
      availableDelta: transaction.amount,
      bookedDelta: transaction.status == TransactionStatus.pending
          ? 0
          : transaction.amount,
    );
  }

  void _adjustCardBalance({
    required String cardId,
    required double availableDelta,
    required double bookedDelta,
  }) {
    for (int index = 0; index < _cards.length; index++) {
      final current = _cards[index];
      if (current.id != cardId) {
        continue;
      }
      _cards[index] = current.copyWith(
        availableBalance: current.availableBalance + availableDelta,
        bookedBalance: current.bookedBalance + bookedDelta,
      );
      return;
    }
  }

  void _settlePendingTransactions() {
    for (int index = 0; index < _transactions.length; index++) {
      final transaction = _transactions[index];
      if (transaction.status != TransactionStatus.pending) {
        continue;
      }

      final bool isSettled =
          DateTime.now().difference(transaction.date) >=
          AppConstants.pendingSettlementDelay;
      if (!isSettled) {
        continue;
      }

      _transactions[index] = transaction.copyWith(
        status: TransactionStatus.booked,
      );
      _adjustCardBalance(
        cardId: transaction.cardId,
        availableDelta: 0,
        bookedDelta: transaction.amount,
      );
    }
  }

  List<Transaction> _withSettledStatuses(List<Transaction> items) {
    return items
        .map((transaction) => _applySettlementStatus(transaction))
        .toList(growable: false);
  }

  Transaction _applySettlementStatus(Transaction transaction) {
    if (transaction.status != TransactionStatus.pending) {
      return transaction;
    }

    final bool isSettled =
        DateTime.now().difference(transaction.date) >=
        AppConstants.pendingSettlementDelay;
    if (!isSettled) {
      return transaction;
    }

    return transaction.copyWith(status: TransactionStatus.booked);
  }

  List<Transaction> _sortedTransactions(List<Transaction> items) {
    return List<Transaction>.from(items)..sort(
      (Transaction left, Transaction right) => right.date.compareTo(left.date),
    );
  }
}
