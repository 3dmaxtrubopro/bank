import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants.dart';
import '../../data/models/transaction.dart';
import '../../providers/selected_card_provider.dart';
import '../../providers/transaction_provider.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedCard = ref.watch(selectedCardProvider);
    final transactionsAsync = ref.watch(transactionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: SafeArea(
        child: Padding(
          padding: AppLayout.screenPadding,
          child: transactionsAsync.when(
            data: (_) {
              final groupedTransactions = ref.watch(groupedTransactionsProvider);
              final entries = groupedTransactions.entries.toList(growable: false);

              return ListView.separated(
                itemCount: entries.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _Header(
                      title: selectedCard == null
                          ? 'Recent activity'
                          : '${selectedCard.label} activity',
                      subtitle: selectedCard == null
                          ? 'A summary of incoming and outgoing transactions.'
                          : 'Transactions for ${selectedCard.maskedNumber}.',
                    );
                  }

                  final entry = entries[index - 1];

                  return _TransactionSection(
                    date: entry.key,
                    transactions: entry.value,
                  );
                },
              );
            },
            loading: () => const _TransactionsSkeleton(),
            error: (error, stackTrace) => Center(
              child: Text(
                'Unable to load transactions: $error',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.displaySmall),
        const SizedBox(height: 8),
        Text(subtitle, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _TransactionSection extends StatelessWidget {
  const _TransactionSection({
    required this.date,
    required this.transactions,
  });

  final DateTime date;
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headingFormat = DateFormat('dd MMM yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headingFormat.format(date),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.panel,
            borderRadius: AppLayout.cardRadius,
            border: Border.fromBorderSide(BorderSide(color: AppColors.line)),
          ),
          child: Column(
            children: [
              for (var index = 0; index < transactions.length; index++) ...[
                _TransactionRow(transaction: transactions[index]),
                if (index != transactions.length - 1)
                  const Divider(height: 1, thickness: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = transaction.amount >= 0;
    final amountFormat = NumberFormat.currency(
      locale: AppConstants.currencyLocale,
      symbol: '${transaction.currency} ',
      decimalDigits: 2,
    );
    final timeFormat = DateFormat('HH:mm');

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isPositive ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: isPositive ? AppColors.success : AppColors.ink,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(transaction.subtitle, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountFormat.format(transaction.amount),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isPositive ? AppColors.success : AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeFormat.format(transaction.date),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionsSkeleton extends StatelessWidget {
  const _TransactionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _Header(
          title: 'Recent activity',
          subtitle: 'A summary of incoming and outgoing transactions.',
        ),
        const SizedBox(height: 24),
        for (var section = 0; section < 2; section++) ...[
          Shimmer.fromColors(
            baseColor: AppColors.line,
            highlightColor: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 184,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppLayout.cardRadius,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}
