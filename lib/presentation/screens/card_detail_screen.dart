import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models/card.dart';
import '../../data/models/transaction.dart';
import '../../providers/card_provider.dart';
import '../../providers/selected_card_provider.dart';
import '../../providers/transaction_provider.dart';

class CardDetailScreen extends ConsumerStatefulWidget {
  const CardDetailScreen({required this.cardId, super.key});

  final String cardId;

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedCardIdProvider.notifier).state = widget.cardId;
    });
  }

  void _showPreviewAction(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label is available in this preview build only.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardsAsync = ref.watch(cardProvider);
    final selectedCardId = ref.watch(selectedCardIdProvider);
    final transactions = ref.watch(selectedCardTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Card details')),
      body: SafeArea(
        child: cardsAsync.when(
          data: (List<Card> cards) {
            final Card? card = _resolveCard(cards, selectedCardId);
            if (card == null) {
              return _EmptyState(cardId: widget.cardId);
            }

            final List<Transaction> cardTransactions = _filterTransactions(
              transactions,
              card.id,
            );

            return ListView(
              padding: AppLayout.screenPadding,
              children: [
                _HeroCard(
                  card: card,
                  onShowDetails: () =>
                      _showPreviewAction(context, 'Full card number'),
                ),
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'Overview',
                  child: Column(
                    children: [
                      _InfoRow(label: 'Cardholder', value: card.holderName),
                      const Divider(),
                      _InfoRow(label: 'Account', value: card.iban),
                      const Divider(),
                      _InfoRow(
                        label: 'Status',
                        value: card.isPrimary ? 'Primary card' : 'Active card',
                      ),
                      const Divider(),
                      _InfoRow(label: 'Reference', value: card.id),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Controls',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _ActionChip(
                        icon: Icons.lock_outline_rounded,
                        label: 'Freeze card',
                        onPressed: () =>
                            _showPreviewAction(context, 'Freeze card'),
                      ),
                      _ActionChip(
                        icon: Icons.pin_outlined,
                        label: 'Reveal PIN',
                        onPressed: () =>
                            _showPreviewAction(context, 'Reveal PIN'),
                      ),
                      _ActionChip(
                        icon: Icons.swap_horiz_rounded,
                        label: 'Set limits',
                        onPressed: () =>
                            _showPreviewAction(context, 'Spending limits'),
                      ),
                      _ActionChip(
                        icon: Icons.travel_explore_outlined,
                        label: 'Travel notice',
                        onPressed: () =>
                            _showPreviewAction(context, 'Travel notice'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Recent activity',
                  trailing: Text(
                    '${cardTransactions.length} items',
                    style: theme.textTheme.bodyMedium,
                  ),
                  child: cardTransactions.isEmpty
                      ? const _EmptyTransactionsState()
                      : Column(
                          children: [
                            for (
                              int index = 0;
                              index < cardTransactions.length && index < 3;
                              index++
                            ) ...[
                              _TransactionPreviewRow(
                                transaction: cardTransactions[index],
                              ),
                              if (index < cardTransactions.length - 1 &&
                                  index < 2)
                                const Divider(),
                            ],
                          ],
                        ),
                ),
              ],
            );
          },
          loading: () => const _LoadingState(),
          error: (Object error, StackTrace stackTrace) {
            return _ErrorState(message: error.toString());
          },
        ),
      ),
    );
  }

  Card? _resolveCard(List<Card> cards, String? selectedCardId) {
    for (final Card card in cards) {
      if (card.id == widget.cardId) {
        return card;
      }
    }

    if (selectedCardId != null) {
      for (final Card card in cards) {
        if (card.id == selectedCardId) {
          return card;
        }
      }
    }

    return null;
  }

  List<Transaction> _filterTransactions(
    List<Transaction> transactions,
    String cardId,
  ) {
    return transactions
        .where((Transaction transaction) => transaction.cardId == cardId)
        .toList(growable: false);
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.card, required this.onShowDetails});

  final Card card;
  final VoidCallback onShowDetails;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: AppConstants.currencyLocale,
      symbol: '${card.currency} ',
      decimalDigits: 2,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppLayout.cardRadius,
        border: Border.all(color: colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.label, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(card.holderName, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              if (card.isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colorScheme.primary),
                  ),
                  child: Text(
                    'Primary',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            card.maskedNumber,
            style: theme.textTheme.headlineMedium?.copyWith(letterSpacing: 1.8),
          ),
          const SizedBox(height: 16),
          Text(
            currencyFormat.format(card.balance),
            style: theme.textTheme.displaySmall?.copyWith(fontSize: 30),
          ),
          const SizedBox(height: 8),
          Text('Available balance', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: onShowDetails,
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Show details'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppLayout.cardRadius,
        border: Border.fromBorderSide(BorderSide(color: colorScheme.outline)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
            child,
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
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ActionChip(
      avatar: Icon(icon, size: 18, color: theme.colorScheme.primary),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}

class _TransactionPreviewRow extends StatelessWidget {
  const _TransactionPreviewRow({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isPositive = transaction.amount >= 0;
    final ColorScheme colorScheme = theme.colorScheme;
    final NumberFormat amountFormat = NumberFormat.currency(
      locale: AppConstants.currencyLocale,
      symbol: '${transaction.currency} ',
      decimalDigits: 2,
    );
    final DateFormat timeFormat = DateFormat('dd MMM, HH:mm');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outline),
            ),
            alignment: Alignment.center,
            child: Text(transaction.emoji, style: theme.textTheme.titleMedium),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '${transaction.subtitle} • ${timeFormat.format(transaction.date)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amountFormat.format(transaction.amount),
            style: theme.textTheme.titleMedium?.copyWith(
              color: isPositive ? theme.successColor : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: AppLayout.screenPadding,
      children: [
        SizedBox(
          height: 260,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: AppLayout.cardRadius,
              border: Border.all(color: colorScheme.primary),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 180,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: AppLayout.cardRadius,
              border: Border.all(color: colorScheme.outline),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: AppLayout.screenPadding,
        child: Text(
          'Unable to load card details: $message',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.cardId});

  final String cardId;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: AppLayout.screenPadding,
        child: Text(
          'Card $cardId was not found in the current dataset.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _EmptyTransactionsState extends StatelessWidget {
  const _EmptyTransactionsState();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Text(
      'No recent activity is available for this card yet.',
      style: theme.textTheme.bodyMedium,
    );
  }
}
