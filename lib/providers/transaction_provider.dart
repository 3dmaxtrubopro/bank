import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/transaction.dart';
import 'card_provider.dart';
import 'selected_card_provider.dart';

final transactionProvider = FutureProvider<List<Transaction>>((ref) async {
  final repository = ref.watch(appDataRepositoryProvider);
  final selectedCard = ref.watch(selectedCardProvider);

  if (selectedCard == null) {
    return repository.getTransactions();
  }

  return repository.getTransactionsByCardId(selectedCard.id);
});

final transactionsProvider = transactionProvider;

final selectedCardTransactionsProvider = Provider<List<Transaction>>((ref) {
  return ref.watch(transactionProvider).valueOrNull ?? const <Transaction>[];
});

final groupedTransactionsProvider = Provider<Map<DateTime, List<Transaction>>>((
  ref,
) {
  final List<Transaction> transactions = ref.watch(
    selectedCardTransactionsProvider,
  );
  final Map<DateTime, List<Transaction>> grouped =
      <DateTime, List<Transaction>>{};

  for (final Transaction transaction in transactions) {
    final DateTime key = DateTime(
      transaction.date.year,
      transaction.date.month,
      transaction.date.day,
    );
    grouped.putIfAbsent(key, () => <Transaction>[]).add(transaction);
  }

  return grouped;
});
