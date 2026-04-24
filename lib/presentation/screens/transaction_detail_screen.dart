import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_icons.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models/transaction.dart';
import '../../providers/card_provider.dart';
import '../../providers/transaction_provider.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({required this.transactionId, super.key});

  final String transactionId;

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends ConsumerState<TransactionDetailScreen> {
  static const List<String> _emojiOptions = <String>[
    '💳',
    '🛒',
    '🍽️',
    '☕',
    '🧾',
    '🚕',
    '🏠',
    '🎬',
    '🎵',
    '🧑‍💻',
    '📈',
    '💸',
    '✈️',
    '🏥',
    '🎁',
    '📚',
    '🍔',
    '🛍️',
    '🚇',
    '⛽',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionAsync = ref.watch(
      transactionByIdProvider(widget.transactionId),
    );

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
                  OutlinedButton.icon(
                    onPressed: () => _showEditTransactionDialog(transaction),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit transaction'),
                  ),
                  const SizedBox(height: 12),
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
                    icon: const Icon(AppIcons.repeat),
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

  Future<void> _showEditTransactionDialog(Transaction transaction) async {
    final titleController = TextEditingController(text: transaction.title);
    final subtitleController = TextEditingController(text: transaction.subtitle);
    String selectedEmoji = transaction.emoji.trim().isEmpty
        ? _emojiOptions.first
        : transaction.emoji;
    final emojiController = TextEditingController(text: selectedEmoji);
    final messenger = ScaffoldMessenger.of(context);
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Modifier la transaction'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Titre'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: subtitleController,
                      decoration: const InputDecoration(labelText: 'Sous-titre'),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Emoji',
                        style: Theme.of(
                          dialogContext,
                        ).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final emoji in _emojiOptions)
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              setDialogState(() {
                                selectedEmoji = emoji;
                                emojiController.text = emoji;
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedEmoji == emoji
                                      ? Theme.of(dialogContext).colorScheme.primary
                                      : Theme.of(dialogContext).colorScheme.outline,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emojiController,
                      decoration: const InputDecoration(
                        labelText: 'Emoji personnalisé',
                        hintText: 'Ex: 🐶',
                      ),
                      onChanged: (value) {
                        final trimmed = value.trim();
                        if (trimmed.isEmpty) {
                          return;
                        }
                        setDialogState(() => selectedEmoji = trimmed);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () async {
                    final repository = ref.read(appDataRepositoryProvider);
                    final ok = await repository.updateTransactionDetails(
                      transactionId: transaction.id,
                      title: titleController.text,
                      subtitle: subtitleController.text,
                      emoji: selectedEmoji,
                    );
                    if (!dialogContext.mounted) {
                      return;
                    }
                    Navigator.of(dialogContext).pop(ok);
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    subtitleController.dispose();
    emojiController.dispose();

    if (!mounted || saved == null) {
      return;
    }
    if (saved) {
      ref
        ..invalidate(transactionProvider)
        ..invalidate(transactionByIdProvider(widget.transactionId));
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? 'Transaction mise à jour.'
                : 'Impossible de mettre à jour la transaction.',
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
