import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/app_icons.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models/transaction.dart';
import '../../providers/card_provider.dart';
import '../../providers/selected_card_provider.dart';
import '../../providers/transaction_provider.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
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
    final selectedCard = ref.watch(selectedCardProvider);
    final transactionsAsync = ref.watch(transactionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: transactionsAsync.when(
            data: (_) {
              final groupedTransactions = ref.watch(
                groupedTransactionsProvider,
              );
              final entries = groupedTransactions.entries.toList(
                growable: false,
              );

              return ListView.separated(
                itemCount: entries.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _Header(
                      title: selectedCard == null
                          ? 'Historique'
                          : 'Historique ${selectedCard.maskedNumber}',
                      subtitle: 'Liste des paiements et transferts récents.',
                    );
                  }

                  final entry = entries[index - 1];
                  return _TransactionSection(
                    date: entry.key,
                    transactions: entry.value,
                    onOpenTransaction: (transactionId) {
                      context.go('/transaction/$transactionId');
                    },
                    onEditTransaction: (transaction) {
                      _showEditTransactionDialog(transaction);
                    },
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

  Future<void> _showEditTransactionDialog(Transaction transaction) async {
    final titleController = TextEditingController(text: transaction.title);
    final subtitleController = TextEditingController(text: transaction.subtitle);
    final amountController = TextEditingController(
      text: transaction.amount.toStringAsFixed(2),
    );
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
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Montant (CHF)',
                        hintText: '-7.05',
                      ),
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
                    final parsedAmount = double.tryParse(
                      amountController.text.replaceAll(',', '.').trim(),
                    );
                    if (parsedAmount == null) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('Montant invalide.'),
                          ),
                        );
                      }
                      return;
                    }
                    final repository = ref.read(appDataRepositoryProvider);
                    final ok = await repository.updateTransactionDetails(
                      transactionId: transaction.id,
                      title: titleController.text,
                      subtitle: subtitleController.text,
                      emoji: selectedEmoji,
                      amount: parsedAmount,
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
    amountController.dispose();
    emojiController.dispose();

    if (!mounted || saved == null) {
      return;
    }
    if (saved) {
      ref
        ..invalidate(transactionProvider)
        ..invalidate(transactionByIdProvider(transaction.id));
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
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(subtitle, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _TransactionSection extends StatelessWidget {
  const _TransactionSection({
    required this.date,
    required this.transactions,
    required this.onOpenTransaction,
    required this.onEditTransaction,
  });

  final DateTime date;
  final List<Transaction> transactions;
  final ValueChanged<String> onOpenTransaction;
  final ValueChanged<Transaction> onEditTransaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headingFormat = DateFormat('dd.MM.yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headingFormat.format(date),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 4),
        for (var index = 0; index < transactions.length; index++) ...[
          _TransactionRow(
            transaction: transactions[index],
            onTap: () {
              onOpenTransaction(transactions[index].id);
            },
            onLongPress: () {
              onEditTransaction(transactions[index]);
            },
          ),
          if (index != transactions.length - 1)
            Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.45),
            ),
        ],
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    required this.onTap,
    required this.onLongPress,
  });

  final Transaction transaction;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPositive = transaction.amount >= 0;
    final merchantName = _originalLikeMerchantName(transaction);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MerchantIcon(transaction: transaction),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                merchantName,
                style: theme.textTheme.titleMedium?.copyWith(height: 1.25),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _compactAmount(transaction.amount),
              style: theme.textTheme.titleMedium?.copyWith(
                color: isPositive ? theme.successColor : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MerchantIcon extends StatelessWidget {
  const _MerchantIcon({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final title = transaction.title.toLowerCase();
    final merchant = _originalLikeMerchantName(transaction).toLowerCase();

    if (title.contains('apple') || merchant.contains('apple')) {
      return const _BrandCircle(
        background: Color(0xFF111111),
        child: Icon(AppIcons.apple, color: Colors.white, size: 20),
      );
    }
    if (title.contains('twint') || merchant.contains('twint')) {
      return _BrandCircle(
        background: const Color(0xFF0A0A0A),
        child: Text(
          'T',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    if (title.contains('kiosk') || merchant.contains('kiosk')) {
      return _BrandCircle(
        background: const Color(0xFFE94352),
        child: Text(
          'K',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    if (transaction.emoji.trim().isNotEmpty) {
      return _BrandCircle(
        background: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Text(transaction.emoji, style: const TextStyle(fontSize: 18)),
      );
    }

    return _BrandCircle(
      background: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        AppIcons.wallet,
        color: Theme.of(context).colorScheme.primary,
        size: 18,
      ),
    );
  }
}

class _BrandCircle extends StatelessWidget {
  const _BrandCircle({required this.background, required this.child});

  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _TransactionsSkeleton extends StatelessWidget {
  const _TransactionsSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      children: [
        const _Header(
          title: 'Historique',
          subtitle: 'Liste des paiements et transferts récents.',
        ),
        const SizedBox(height: 20),
        for (var section = 0; section < 3; section++) ...[
          Shimmer.fromColors(
            baseColor: colorScheme.outlineVariant,
            highlightColor: colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 92,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

String _compactAmount(double amount) {
  final abs = amount.abs();
  final formatted = NumberFormat(
    "0.00",
    AppConstants.currencyLocale,
  ).format(abs);
  return '$formatted${amount >= 0 ? '+' : '-'}';
}

String _originalLikeMerchantName(Transaction transaction) {
  final subtitle = transaction.subtitle.trim();
  if (subtitle.isNotEmpty &&
      !subtitle.toLowerCase().contains('achat') &&
      !subtitle.toLowerCase().contains('service')) {
    return subtitle;
  }

  final title = transaction.title.trim();
  if (title.contains(',')) {
    return title.split(',').last.trim();
  }
  if (title.toLowerCase().contains('twint')) {
    return 'TWINT';
  }
  return title;
}
