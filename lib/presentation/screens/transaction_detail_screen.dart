import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models/transaction.dart';
import '../../providers/transaction_provider.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({required this.transactionId, super.key});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final transactionAsync = ref.watch(transactionByIdProvider(transactionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction details')),
      body: SafeArea(
        child: Padding(
          padding: AppLayout.screenPadding,
          child: transactionAsync.when(
            data: (transaction) {
              if (transaction == null) {
                return Center(
                  child: Text(
                    'Transaction not found.',
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }

              final amountFormat = NumberFormat.currency(
                locale: AppConstants.currencyLocale,
                symbol: '${transaction.currency} ',
                decimalDigits: 2,
              );
              final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

              return ListView(
                children: [
                  _SummaryCard(
                    transaction: transaction,
                    amount: amountFormat.format(transaction.amount),
                    dateLabel: dateFormat.format(transaction.date),
                  ),
                  const SizedBox(height: 16),
                  _DetailsCard(transaction: transaction),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      final recipient = _deriveRecipient(transaction);
                      final note = transaction.subtitle;
                      final amount = transaction.amount.abs().toStringAsFixed(
                        2,
                      );
                      context.go(
                        '/transfer?recipient=${Uri.encodeComponent(recipient)}'
                        '&note=${Uri.encodeComponent(note)}'
                        '&amount=${Uri.encodeComponent(amount)}',
                      );
                    },
                    icon: const Icon(Icons.repeat_rounded),
                    label: const Text('Repeat transfer'),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Text(
                'Unable to load transaction: $error',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.transaction,
    required this.amount,
    required this.dateLabel,
  });

  final Transaction transaction;
  final String amount;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPositive = transaction.amount >= 0;
    final isPending = transaction.status == TransactionStatus.pending;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppLayout.cardRadius,
        border: Border.all(color: colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(transaction.emoji, style: theme.textTheme.headlineMedium),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPending
                        ? colorScheme.primary.withValues(alpha: 0.18)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isPending ? 'Pending' : 'Booked',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(transaction.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              amount,
              style: theme.textTheme.displaySmall?.copyWith(
                color: isPositive ? theme.successColor : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(dateLabel, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppLayout.cardRadius,
        border: Border.all(color: colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Details', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            _InfoRow(label: 'Reference', value: transaction.id),
            _InfoRow(label: 'Category', value: transaction.subtitle),
            _InfoRow(label: 'Card ID', value: transaction.cardId),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: theme.textTheme.titleMedium)),
        ],
      ),
    );
  }
}

String _deriveRecipient(Transaction transaction) {
  const prefix = 'Transfer to ';
  if (transaction.title.startsWith(prefix) &&
      transaction.title.length > prefix.length) {
    return transaction.title.substring(prefix.length);
  }
  return transaction.title;
}
